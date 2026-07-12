package com.traverseframework.starter

import kotlinx.serialization.json.JsonElement

@kotlinx.serialization.Serializable
data class ValidateOutput(
    val valid: Boolean,
    val issues: List<String>,
)

@kotlinx.serialization.Serializable
data class ProcessOutput(
    val title: String,
    val tags: List<String>,
    val noteType: String,
    val suggestedNextAction: String,
    val status: String,
)

@kotlinx.serialization.Serializable
data class SummarizeOutput(
    val summary: String,
    val wordCount: Int,
)

/** Combined pipeline final output (validate → process → summarize). */
@kotlinx.serialization.Serializable
data class TraverseStarterOutput(
    val validate: ValidateOutput,
    val process: ProcessOutput,
    val summarize: SummarizeOutput,
) {
    companion object {
        val EMPTY = TraverseStarterOutput(
            validate = ValidateOutput(valid = false, issues = emptyList()),
            process = ProcessOutput(
                title = "",
                tags = emptyList(),
                noteType = "",
                suggestedNextAction = "",
                status = "",
            ),
            summarize = SummarizeOutput(summary = "", wordCount = 0),
        )
    }
}

@kotlinx.serialization.Serializable
data class TraceEvent(
    val event_type: String,
    val timestamp: String,
    val data: JsonElement? = null,
)

@kotlinx.serialization.Serializable
data class ExecuteResponse(
    val execution_id: String,
)

@kotlinx.serialization.Serializable
data class ExecutionPollResponse(
    val execution_id: String? = null,
    val status: String,
    val output: TraverseStarterOutput? = null,
    val error: String? = null,
)

data class ExecutionPollResult(
    val executionId: String,
    val status: String,
    val output: TraverseStarterOutput?,
    val error: String?,
)

object AppConstants {
    const val CAPABILITY_ID = "traverse-starter.pipeline"
    const val DEFAULT_BASE_URL = "http://10.0.2.2:8787"
    const val DEFAULT_WORKSPACE = "local-default"
    const val NOTE_MAX_LENGTH = 2000
}
