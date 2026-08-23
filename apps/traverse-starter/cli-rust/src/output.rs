use colored::Colorize;
use serde::Serialize;
use serde_json::Value;

use crate::client::{TraceEvent, TraverseStarterOutput};

#[derive(Debug, Serialize)]
pub struct RunResultJson {
    pub execution_id: String,
    pub output: TraverseStarterOutput,
    pub trace: Vec<TraceEvent>,
    pub presentation_state: String,
    pub presentation_error: Option<String>,
    pub active_capability_id: Option<String>,
}

pub fn print_json(value: &Value) {
    println!("{}", serde_json::to_string_pretty(value).unwrap_or_default());
}

pub fn print_run_result(result: &RunResultJson, json: bool) {
    if json {
        println!("{}", serde_json::to_string_pretty(result).unwrap_or_default());
        return;
    }

    let output = &result.output;
    println!(
        "Valid: {}",
        if output.validate.valid { "yes" } else { "no" }.bold()
    );
    println!(
        "Issues: {}",
        if output.validate.issues.is_empty() {
            "None".to_string()
        } else {
            output.validate.issues.join(", ")
        }
    );
    println!("Title: {}", output.process.title.bold());
    println!("Note type: {}", output.process.note_type);
    println!("Status: {}", output.process.status);
    println!("Next action: {}", output.process.suggested_next_action);
    println!("Tags: {}", output.process.tags.join(", "));
    println!("Summary: {}", output.summarize.summary);
    println!("Word count: {}", output.summarize.word_count);
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
