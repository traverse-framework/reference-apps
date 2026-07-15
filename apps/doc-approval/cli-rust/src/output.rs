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
    println!("Document type: {}", output.analysis.doc_type.bold());
    println!("Parties: {}", output.analysis.parties.join(", "));
    println!("Amounts: {}", output.analysis.amounts.join(", "));
    println!("Analyze confidence: {}", output.analysis.confidence);
    println!("Analyze recommendation: {}", output.analysis.recommendation);
    println!(
        "Recommendation: {}",
        output.recommendation.recommendation.bold()
    );
    println!("Rationale: {}", output.recommendation.rationale);
    println!("Recommend confidence: {}", output.recommendation.confidence);
    if !result.trace.is_empty() {
        println!("Trace ({} events):", result.trace.len());
        for event in &result.trace {
            println!("  {} · {}", event.timestamp, event.event_type);
        }
    }
}
