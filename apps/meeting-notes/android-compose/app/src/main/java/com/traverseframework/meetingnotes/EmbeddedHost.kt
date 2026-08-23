package com.traverseframework.meetingnotes

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.io.File

/**
 * Embedded Traverse host for meeting-notes.
 *
 * Production uses the public Kotlin `dev.traverse.embedder` package.
 * Unit tests inject [InMemoryMeetingNotesHost] with scripted runtime-owned output.
 */
interface MeetingNotesHost {
    val runtimeMode: String
    val isReady: Boolean
    fun submitTranscript(transcript: String): HostRunResult
}

data class HostRunResult(
    val sessionId: String,
    val output: MeetingNotesOutput?,
    val events: List<TraceEvent>,
    val error: String?,
    val presentationState: PresentationState = PresentationState.Idle,
    val presentationError: String? = null,
    val capabilityProgress: List<CapabilityProgressStep> = emptyList(),
    val activeCapabilityId: String? = null,
) {
    fun withPresentation(likes: List<EmbedderEventLike>): HostRunResult {
        val snap = PresentationMapper.mapPresentationState(likes)
        val state =
            if (error != null && snap.state == PresentationState.Idle) {
                PresentationState.Error
            } else {
                snap.state
            }
        return copy(
            presentationState = state,
            presentationError = snap.errorMessage
                ?: if (error != null && snap.state == PresentationState.Idle) error else null,
            capabilityProgress = PresentationMapper.mapCapabilityProgress(likes),
            activeCapabilityId = PresentationMapper.activeCapabilityId(likes),
        )
    }
}

/** Deterministic test double wrapping [dev.traverse.embedder.InMemoryTraverseEmbedder]. */
class InMemoryMeetingNotesHost(
    private val scriptedOutputJson: String,
) : MeetingNotesHost {
    override val runtimeMode: String = AppConstants.RUNTIME_MODE_EMBEDDED
    override val isReady: Boolean = true

    private val embedder = dev.traverse.embedder.InMemoryTraverseEmbedder()
        .withTargetOutput(scriptedOutputJson)
        .also {
            it.initialize(
                dev.traverse.embedder.TraverseBundle(
                    rootPath = "test-bundle",
                    runtimeWasmDigest = "sha256:test",
                ),
            )
        }

    override fun submitTranscript(transcript: String): HostRunResult {
        val inputJson = buildJsonObject { put("transcript", transcript) }.toString()
        val result = embedder.submit(
            dev.traverse.embedder.TraverseSubmission(AppConstants.CAPABILITY_ID, inputJson),
        )
        val events = embedder.subscribe()
        val outputJson = events.firstOrNull { it.eventType == "capability_result" }?.output
        val output = outputJson?.let { parseOutput(it) }
        return HostRunResult(
            sessionId = result.sessionId,
            output = output,
            events = events.map {
                TraceEvent(
                    event_type = it.eventType ?: it.status,
                    timestamp = it.sequence.toString(),
                    data = null,
                )
            },
            error = if (output == null) "embedder emitted no capability_result output" else null,
        ).withPresentation(emptyList())
    }

    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        fun parseOutput(raw: String): MeetingNotesOutput? = try {
            json.decodeFromString(MeetingNotesOutput.serializer(), raw)
        } catch (_: Exception) {
            null
        }

        fun withScriptedOutput(output: MeetingNotesOutput): InMemoryMeetingNotesHost =
            InMemoryMeetingNotesHost(json.encodeToString(MeetingNotesOutput.serializer(), output))
    }
}

/**
 * Production host: digest-pinned `runtime/runtime.wasm` via public [RuntimeTraverseEmbedder]
 * constructed from [TraverseBundle] (public constructor).
 */
class ProductionMeetingNotesHost private constructor(
    private val embedder: dev.traverse.embedder.RuntimeTraverseEmbedder,
) : MeetingNotesHost {
    override val runtimeMode: String = AppConstants.RUNTIME_MODE_EMBEDDED
    override val isReady: Boolean = true

    override fun submitTranscript(transcript: String): HostRunResult = try {
        val inputJson = buildJsonObject { put("transcript", transcript) }.toString()
        val result = embedder.submit(
            dev.traverse.embedder.TraverseSubmission(AppConstants.CAPABILITY_ID, inputJson),
        )
        val runtimeEvents = embedder.subscribe()
        val events = runtimeEvents.map {
            TraceEvent(
                event_type = it.eventType ?: it.status,
                timestamp = it.sequence.toString(),
                data = null,
            )
        }
        val output = runtimeEvents
            .firstOrNull { it.eventType == "capability_result" || it.output != null }
            ?.output
            ?.let { InMemoryMeetingNotesHost.parseOutput(it) }
        HostRunResult(
            sessionId = result.sessionId,
            output = output,
            events = events,
            error = if (output == null) {
                "runtime returned no meeting-notes output"
            } else {
                null
            },
        ).withPresentation(emptyList())
    } catch (e: Exception) {
        HostRunResult("", null, emptyList(), e.message ?: "submit failed")
            .withPresentation(emptyList())
    }

    companion object {
        fun createOrNull(bundleRoot: File): ProductionMeetingNotesHost? {
            val wasm = File(bundleRoot, "runtime/runtime.wasm")
            val release = File(bundleRoot, "runtime/runtime-release.json")
            if (!wasm.isFile || !release.isFile) return null
            val digestHex = Regex("\"sha256\"\\s*:\\s*\"([^\"]+)\"")
                .find(release.readText())
                ?.groupValues
                ?.get(1)
                ?: return null
            return try {
                val bundle = dev.traverse.embedder.TraverseBundle(
                    rootPath = bundleRoot.absolutePath,
                    runtimeWasmDigest = "sha256:$digestHex",
                )
                val embedder = dev.traverse.embedder.RuntimeTraverseEmbedder(bundle)
                embedder.initialize("{}")
                ProductionMeetingNotesHost(embedder)
            } catch (_: Exception) {
                null
            }
        }
    }
}
