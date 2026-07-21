//! Runtime-owned output types for traverse-starter shells.
//!
//! HTTP sidecar clients were removed — production uses the embedded host only
//! (`host` module). See `docs/traverse-runtime.md` for the deprecated appendix.

use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct ValidateOutput {
    pub valid: bool,
    pub issues: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct ProcessOutput {
    pub title: String,
    pub tags: Vec<String>,
    #[serde(rename = "noteType")]
    pub note_type: String,
    #[serde(rename = "suggestedNextAction")]
    pub suggested_next_action: String,
    pub status: String,
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct SummarizeOutput {
    pub summary: String,
    #[serde(rename = "wordCount")]
    pub word_count: u64,
}

/// Combined pipeline final output (validate → process → summarize).
#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct TraverseStarterOutput {
    pub validate: ValidateOutput,
    pub process: ProcessOutput,
    pub summarize: SummarizeOutput,
}

impl TraverseStarterOutput {
    pub fn empty() -> Self {
        Self {
            validate: ValidateOutput {
                valid: false,
                issues: vec![],
            },
            process: ProcessOutput {
                title: String::new(),
                tags: vec![],
                note_type: String::new(),
                suggested_next_action: String::new(),
                status: String::new(),
            },
            summarize: SummarizeOutput {
                summary: String::new(),
                word_count: 0,
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
