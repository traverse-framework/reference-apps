//! Runtime-owned output types for doc-approval shells.
//!
//! HTTP sidecar clients were removed — production uses the embedded host only
//! (`host` module). See `docs/traverse-runtime.md` for the deprecated appendix.

use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;

fn stringish<'de, D: Deserializer<'de>>(deserializer: D) -> Result<String, D::Error> {
    let value = Value::deserialize(deserializer)?;
    match value {
        Value::String(s) => Ok(s),
        Value::Number(n) => Ok(n.to_string()),
        other => Err(serde::de::Error::custom(format!(
            "expected string or number, got {other}"
        ))),
    }
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct AnalysisOutput {
    #[serde(rename = "docType")]
    pub doc_type: String,
    pub parties: Vec<String>,
    pub amounts: Vec<String>,
    #[serde(deserialize_with = "stringish")]
    pub confidence: String,
    pub recommendation: String,
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct RecommendationOutput {
    pub recommendation: String,
    pub rationale: String,
    #[serde(deserialize_with = "stringish")]
    pub confidence: String,
}

/// Combined pipeline final output (analyze → recommend).
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct DocApprovalOutput {
    pub analysis: AnalysisOutput,
    pub recommendation: RecommendationOutput,
}

impl DocApprovalOutput {
    pub fn empty() -> Self {
        Self {
            analysis: AnalysisOutput {
                doc_type: String::new(),
                parties: vec![],
                amounts: vec![],
                confidence: String::new(),
                recommendation: String::new(),
            },
            recommendation: RecommendationOutput {
                recommendation: String::new(),
                rationale: String::new(),
                confidence: String::new(),
            },
        }
    }
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct TraceEvent {
    pub event_type: String,
    pub timestamp: String,
    pub data: Option<Value>,
}
