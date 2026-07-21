package com.traverseframework.starter

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.io.File

/**
 * Embedded Traverse host for traverse-starter.
 *
 * Production uses the public Kotlin `dev.traverse.embedder` package.
 * Unit tests inject [InMemoryStarterHost] with scripted runtime-owned output —
 * never compute business fields in the UI layer.
 */
interface StarterHost {
    val runtimeMode: String
    val isReady: Boolean
    fun submitNote(note: String): HostRunResult
}

data class HostRunResult(
    val sessionId: String,
    val output: TraverseStarterOutput?,
    val events: List<TraceEvent>,
    val error: String?,
)

/** Deterministic test double wrapping [dev.traverse.embedder.InMemoryTraverseEmbedder]. */
class InMemoryStarterHost(
    private val scriptedOutputJson: String,
) : StarterHost {
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

    override fun submitNote(note: String): HostRunResult {
        val inputJson = buildJsonObject { put("note", note) }.toString()
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
        )
    }

    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        fun parseOutput(raw: String): TraverseStarterOutput? = try {
            json.decodeFromString(TraverseStarterOutput.serializer(), raw)
        } catch (_: Exception) {
            null
        }

        fun withScriptedOutput(output: TraverseStarterOutput): InMemoryStarterHost =
            InMemoryStarterHost(json.encodeToString(TraverseStarterOutput.serializer(), output))
    }
}

/**
 * Production host: digest-pinned `runtime/runtime.wasm` via public [RuntimeTraverseEmbedder]
 * constructed from [TraverseBundle] (public constructor).
 */
class ProductionStarterHost private constructor(
    private val embedder: dev.traverse.embedder.RuntimeTraverseEmbedder,
) : StarterHost {
    override val runtimeMode: String = AppConstants.RUNTIME_MODE_EMBEDDED
    override val isReady: Boolean = true

    override fun submitNote(note: String): HostRunResult = try {
        val inputJson = buildJsonObject { put("note", note) }.toString()
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
            ?.let { InMemoryStarterHost.parseOutput(it) }
        HostRunResult(
            sessionId = result.sessionId,
            output = output,
            events = events,
            error = if (output == null) {
                "runtime returned no pipeline output"
            } else {
                null
            },
        )
    } catch (e: Exception) {
        HostRunResult("", null, emptyList(), e.message ?: "submit failed")
    }

    companion object {
        fun createOrNull(bundleRoot: File): ProductionStarterHost? {
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
                ProductionStarterHost(embedder)
            } catch (_: Exception) {
                null
            }
        }
    }
}
