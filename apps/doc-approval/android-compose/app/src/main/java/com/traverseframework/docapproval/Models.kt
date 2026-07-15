package com.traverseframework.docapproval

import kotlinx.serialization.json.JsonElement

@kotlinx.serialization.Serializable
data class AnalysisOutput(
    val docType: String,
    val parties: List<String>,
    val amounts: List<String>,
    val confidence: String,
    val recommendation: String,
)

@kotlinx.serialization.Serializable
data class RecommendationOutput(
    val recommendation: String,
    val rationale: String,
    val confidence: String,
)

/** Combined pipeline final output (analyze → recommend). */
@kotlinx.serialization.Serializable
data class DocApprovalOutput(
    val analysis: AnalysisOutput,
    val recommendation: RecommendationOutput,
) {
    companion object {
        val EMPTY = DocApprovalOutput(
            analysis = AnalysisOutput(
                docType = "",
                parties = emptyList(),
                amounts = emptyList(),
                confidence = "",
                recommendation = "",
            ),
            recommendation = RecommendationOutput(
                recommendation = "",
                rationale = "",
                confidence = "",
            ),
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
    val output: DocApprovalOutput? = null,
    val error: String? = null,
)

data class ExecutionPollResult(
    val executionId: String,
    val status: String,
    val output: DocApprovalOutput?,
    val error: String?,
)

object AppConstants {
    const val CAPABILITY_ID = "doc-approval.pipeline"
    const val DEFAULT_BASE_URL = "http://10.0.2.2:8787"
    const val DEFAULT_WORKSPACE = "local-default"
}
