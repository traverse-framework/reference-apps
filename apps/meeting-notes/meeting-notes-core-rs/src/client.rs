//! Runtime-owned output types for meeting-notes shells.

use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct ActionItem {
    pub task: String,
    pub owner: Option<String>,
    pub due: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct Decision {
    pub text: String,
    pub made_by: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct MeetingNotesOutput {
    pub action_items: Vec<ActionItem>,
    pub decisions: Vec<Decision>,
    pub follow_ups: Vec<String>,
    pub summary: String,
}

impl MeetingNotesOutput {
    pub fn empty() -> Self {
        Self {
            action_items: vec![],
            decisions: vec![],
            follow_ups: vec![],
            summary: String::new(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct TraceEvent {
    pub event_type: String,
    pub timestamp: String,
    pub data: Option<Value>,
}
