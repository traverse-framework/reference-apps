use colored::Colorize;
use serde::Serialize;

use crate::client::{DocApprovalOutput, TraceEvent};

#[derive(Debug, Serialize)]
pub struct SubmitResultJson {
    pub execution_id: String,
    pub output: DocApprovalOutput,
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

pub fn print_submit_result(result: &SubmitResultJson, json: bool) {
    if json {
        println!("{}", serde_json::to_string_pretty(result).unwrap_or_default());
        return;
    }

    let output = &result.output;
    println!("Document type: {}", output.doc_type.bold());
    println!("Parties: {}", output.parties.join(", "));
    println!("Amounts: {}", output.amounts.join(", "));
    println!("Confidence: {}", output.confidence);
    println!("Recommendation: {}", output.recommendation);
    if !result.trace.is_empty() {
        println!("Trace ({} events):", result.trace.len());
        for event in &result.trace {
            println!("  {} · {}", event.timestamp, event.event_type);
        }
    }
}
