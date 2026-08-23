use colored::Colorize;
use serde::Serialize;
use serde_json::Value;

use crate::client::{LoopOutput, TraceEvent};

#[derive(Debug, Serialize)]
pub struct SubmitResultJson {
    pub execution_id: String,
    pub output: LoopOutput,
    pub trace: Vec<TraceEvent>,
    pub presentation_state: String,
    pub presentation_error: Option<String>,
    pub active_capability_id: Option<String>,
}

pub fn print_json(value: &Value) {
    println!("{}", serde_json::to_string_pretty(value).unwrap_or_default());
}

pub fn print_submit_result(result: &SubmitResultJson, json: bool) {
    if json {
        println!("{}", serde_json::to_string_pretty(result).unwrap_or_default());
        return;
    }

    let output = &result.output;
    println!("{}", "Summary".bold());
    println!("{}", output.summary);
    println!("{}", "Action items".bold());
    for item in &output.action_items {
        let owner = item.owner.as_deref().unwrap_or("-");
        let due = item.due.as_deref().unwrap_or("-");
        println!("  - {} (owner: {owner}, due: {due})", item.task);
    }
    println!("{}", "Decisions".bold());
    for decision in &output.decisions {
        let made_by = decision.made_by.as_deref().unwrap_or("-");
        println!("  - {} (by: {made_by})", decision.text);
    }
    println!("{}", "Follow-ups".bold());
    for follow_up in &output.follow_ups {
        println!("  - {follow_up}");
    }
    println!("Presentation: {}", result.presentation_state.bold());
    if let Some(active) = &result.active_capability_id {
        println!("Active capability: {active}");
    }
    if let Some(err) = &result.presentation_error {
        println!("Presentation error: {err}");
    }
    if !result.trace.is_empty() {
        println!("Trace ({} events):", result.trace.len());
        for event in &result.trace {
            println!("  {} · {}", event.timestamp, event.event_type);
        }
    }
}
