use colored::Colorize;
use serde::Serialize;
use serde_json::Value;

use crate::client::{DocApprovalOutput, TraceEvent};

#[derive(Debug, Serialize)]
pub struct SubmitResultJson {
    pub execution_id: String,
    pub output: DocApprovalOutput,
    pub trace: Vec<TraceEvent>,
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
