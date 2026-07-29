package com.traverseframework.meetingnotes

import kotlinx.serialization.json.JsonElement

@kotlinx.serialization.Serializable
data class ActionItem(
    val task: String,
    val owner: String? = null,
    val due: String? = null,
)

@kotlinx.serialization.Serializable
data class Decision(
    val text: String,
    val made_by: String? = null,
)

@kotlinx.serialization.Serializable
data class MeetingNotesOutput(
    val action_items: List<ActionItem>,
    val decisions: List<Decision>,
    val follow_ups: List<String>,
    val summary: String,
) {
    companion object {
        val EMPTY = MeetingNotesOutput(
            action_items = emptyList(),
            decisions = emptyList(),
            follow_ups = emptyList(),
            summary = "",
        )
    }
}

@kotlinx.serialization.Serializable
data class TraceEvent(
    val event_type: String,
    val timestamp: String,
    val data: JsonElement? = null,
)

object AppConstants {
    const val CAPABILITY_ID = "meeting-notes.process"
    const val RUNTIME_MODE_EMBEDDED = "Embedded"
    const val DEFAULT_WORKSPACE = "local-default"
    const val TRANSCRIPT_MAX_LENGTH = 5000
    /** Asset-relative bundle root (must include runtime/runtime.wasm after sync). */
    const val BUNDLE_ASSET_DIR = "bundles/meeting-notes"
}
