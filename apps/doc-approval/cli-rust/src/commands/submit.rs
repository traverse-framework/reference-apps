use std::{thread, time::Duration};

use crate::client::{DocApprovalOutput, TraverseClient};
use crate::output::{print_submit_result, SubmitResultJson};
use crate::CAPABILITY_ID;

pub fn execute(base_url: &str, workspace: &str, document: &str, json: bool) -> i32 {
    let client = TraverseClient::new();
    let execution_id = match client.execute(
        base_url,
        workspace,
        CAPABILITY_ID,
        &serde_json::json!({ "document": document }),
    ) {
        Ok(id) => id,
        Err(err) => {
            eprintln!("execute failed: {err}");
            return 1;
        }
    };

    loop {
        match client.poll_execution(base_url, workspace, &execution_id) {
            Ok(result) if result.status == "succeeded" => {
                let trace = client
                    .fetch_trace(base_url, workspace, &execution_id)
                    .unwrap_or_default();
                let output = result.output.unwrap_or(DocApprovalOutput {
                    doc_type: String::new(),
                    parties: vec![],
                    amounts: vec![],
                    confidence: 0.0,
                    recommendation: String::new(),
                });
                print_submit_result(
                    &SubmitResultJson {
                        execution_id,
                        output,
                        trace,
                    },
                    json,
                );
                return 0;
            }
            Ok(result) if result.status == "failed" => {
                eprintln!(
                    "execution failed: {}",
                    result.error.unwrap_or_else(|| "unknown error".to_string())
                );
                return 1;
            }
            Ok(_) => thread::sleep(Duration::from_secs(1)),
            Err(err) => {
                eprintln!("poll failed: {err}");
                return 1;
            }
        }
    }
}
