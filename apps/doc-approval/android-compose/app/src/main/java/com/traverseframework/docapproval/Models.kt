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

object AppConstants {
    const val CAPABILITY_ID = "doc-approval.pipeline"
    const val RUNTIME_MODE_EMBEDDED = "Embedded"
    const val DEFAULT_WORKSPACE = "local-default"
    const val DOCUMENT_MAX_LENGTH = 4000
    /** Asset-relative bundle root (must include runtime/runtime.wasm). */
    const val BUNDLE_ASSET_DIR = "bundles/doc-approval"
}
