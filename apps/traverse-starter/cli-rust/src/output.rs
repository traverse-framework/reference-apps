use colored::Colorize;
use serde::Serialize;

use crate::client::{TraceEvent, TraverseStarterOutput};

#[derive(Debug, Serialize)]
pub struct RunResultJson {
    pub execution_id: String,
    pub output: TraverseStarterOutput,
    pub trace: Vec<TraceEvent>,
}

pub fn print_health(base_url: &str, online: bool, json: bool) {
    if json {
        println!(
            "{}",
            serde_json::to_string(&serde_json::json!({
                "base_url": base_url,
                "status": if online { "online" } else { "offline" },
            }))
            .unwrap_or_default()
        );
        return;
    }

    let status = if online { "online" } else { "offline" };
    println!("Runtime {base_url}: {status}");
}

pub fn print_run_result(result: &RunResultJson, json: bool) {
    if json {
        println!("{}", serde_json::to_string_pretty(result).unwrap_or_default());
        return;
    }

    let output = &result.output;
    println!("Title: {}", output.title.bold());
    println!("Tags: {}", output.tags.join(", "));
    println!("Note type: {}", output.note_type);
    println!("Next action: {}", output.suggested_next_action);
    println!("Status: {}", output.status);
    if !result.trace.is_empty() {
        println!("Trace ({} events):", result.trace.len());
        for event in &result.trace {
            println!("  {} · {}", event.timestamp, event.event_type);
        }
    }
}
