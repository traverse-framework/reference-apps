package com.traverseframework.starter

import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/** Canonical UI presentation states (Spec 001). */
enum class PresentationState {
    Idle,
    Loading,
    Loaded,
    Blocked,
    Ended,
    Error,
    ;

    fun asWire(): String = when (this) {
        Idle -> "idle"
        Loading -> "loading"
        Loaded -> "loaded"
        Blocked -> "blocked"
        Ended -> "ended"
        Error -> "error"
    }
}

data class PresentationSnapshot(
    val state: PresentationState,
    val errorMessage: String?,
    val output: JsonElement?,
)

enum class CapabilityPhase {
    Invoked,
    Result,
    ;

    fun asWire(): String = when (this) {
        Invoked -> "invoked"
        Result -> "result"
    }
}

data class CapabilityProgressStep(
    val capabilityId: String,
    val phase: CapabilityPhase,
    val sequence: Long,
    val status: String?,
    val output: JsonElement?,
)

/** Minimal embedder event fields required by the mapper. */
data class EmbedderEventLike(
    val eventType: String,
    val sequence: Long,
    val data: JsonObject,
)

/**
 * Spec 001/002 presentation + capability progress (language-equivalent of
 * `packages/event-ui-conformance`).
 */
object PresentationMapper {
    private val blockedStates = setOf(
        "blocked",
        "waiting",
        "waiting_for_human",
        "awaiting_human",
        "awaiting_input",
    )
    private val endedStates = setOf("cancelled", "canceled", "closed", "ended")

    fun mapPresentationState(events: List<EmbedderEventLike>): PresentationSnapshot {
        if (events.isEmpty()) {
            return PresentationSnapshot(PresentationState.Idle, null, null)
        }

        var state = PresentationState.Idle
        var errorMessage: String? = null
        var output: JsonElement? = null

        for (event in events) {
            when (event.eventType) {
                "error" -> {
                    state = PresentationState.Error
                    errorMessage = errorMessageFromData(event.data) ?: "execution failed"
                }
                "capability_invoked" -> {
                    if (state != PresentationState.Error) {
                        state = PresentationState.Loading
                    }
                }
                "state_changed" -> {
                    if (state == PresentationState.Error) continue
                    state = when {
                        isBlockedPayload(event.data) -> PresentationState.Blocked
                        isEndedStatePayload(event.data) -> PresentationState.Ended
                        state != PresentationState.Loaded && state != PresentationState.Ended ->
                            PresentationState.Loading
                        else -> state
                    }
                }
                "capability_result" -> {
                    if (state == PresentationState.Error) continue
                    if (hasRenderableOutput(event.data)) {
                        state = PresentationState.Loaded
                        output = event.data["output"]
                    } else {
                        state = PresentationState.Ended
                        output = null
                    }
                }
            }
        }

        return PresentationSnapshot(state, errorMessage, output)
    }

    fun mapCapabilityProgress(events: List<EmbedderEventLike>): List<CapabilityProgressStep> {
        val steps = mutableListOf<CapabilityProgressStep>()
        for (event in events) {
            val capabilityId = stringField(event.data, "capability_id") ?: continue
            when (event.eventType) {
                "capability_invoked" -> steps.add(
                    CapabilityProgressStep(
                        capabilityId = capabilityId,
                        phase = CapabilityPhase.Invoked,
                        sequence = event.sequence,
                        status = null,
                        output = null,
                    ),
                )
                "capability_result" -> steps.add(
                    CapabilityProgressStep(
                        capabilityId = capabilityId,
                        phase = CapabilityPhase.Result,
                        sequence = event.sequence,
                        status = stringField(event.data, "status"),
                        output = event.data["output"],
                    ),
                )
            }
        }
        return steps
    }

    fun activeCapabilityId(events: List<EmbedderEventLike>): String? {
        val progress = mapCapabilityProgress(events)
        val open = mutableMapOf<String, Int>()
        for (step in progress) {
            when (step.phase) {
                CapabilityPhase.Invoked -> open[step.capabilityId] = (open[step.capabilityId] ?: 0) + 1
                CapabilityPhase.Result -> {
                    val count = open[step.capabilityId] ?: 0
                    if (count <= 1) open.remove(step.capabilityId)
                    else open[step.capabilityId] = count - 1
                }
            }
        }
        for (step in progress.asReversed()) {
            if (step.phase == CapabilityPhase.Invoked && open.containsKey(step.capabilityId)) {
                return step.capabilityId
            }
        }
        return null
    }

    private fun stringField(data: JsonObject, key: String): String? =
        data[key]?.jsonPrimitive?.contentOrNull

    private fun errorMessageFromData(data: JsonObject): String? {
        val err = data["error"] ?: return null
        err.jsonPrimitive.contentOrNull?.let { return it }
        return try {
            err.jsonObject["message"]?.jsonPrimitive?.contentOrNull
        } catch (_: Exception) {
            null
        }
    }

    private fun runtimeStateToken(data: JsonObject): String? =
        stringField(data, "state")
            ?: stringField(data, "status")
            ?: stringField(data, "runtime_state")

    private fun isBlockedPayload(data: JsonObject): Boolean {
        if (data["blocked"]?.jsonPrimitive?.booleanOrNull == true) return true
        if (data["waiting_for_human"]?.jsonPrimitive?.booleanOrNull == true) return true
        val token = runtimeStateToken(data)?.lowercase() ?: return false
        return token in blockedStates
    }

    private fun isEndedStatePayload(data: JsonObject): Boolean {
        val token = runtimeStateToken(data)?.lowercase() ?: return false
        return token in endedStates
    }

    private fun hasRenderableOutput(data: JsonObject): Boolean {
        if (!data.containsKey("output")) return false
        val output = data["output"]
        if (output == null || output is JsonNull) return false
        if (output is JsonObject && output.isEmpty()) return false
        return true
    }
}
