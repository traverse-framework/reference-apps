use futures_util::StreamExt;
use doc_approval_core_rs::{AppState, DEFAULT_APP_ID};

use crate::client::{DocApprovalOutput, TraverseClient};
use crate::output::{print_submit_result, SubmitResultJson};

pub fn execute(base_url: &str, workspace: &str, document: &str, json: bool) -> i32 {
    let runtime = match tokio::runtime::Runtime::new() {
        Ok(rt) => rt,
        Err(err) => {
            eprintln!("runtime failed: {err}");
            return 1;
        }
    };

    runtime.block_on(async {
        let client = TraverseClient::new();
        let accepted = match client.submit_document(base_url, workspace, document).await {
            Ok(accepted) => accepted,
            Err(err) => {
                eprintln!("submit failed: {err}");
                return 1;
            }
        };

        let mut stream = match client
            .subscribe_events(base_url, workspace, DEFAULT_APP_ID)
            .await
        {
            Ok(stream) => stream,
            Err(err) => {
                eprintln!("subscribe failed: {err}");
                return 1;
            }
        };

        while let Some(item) = stream.next().await {
            match item {
                Ok(event) if event.event_type == "heartbeat" => continue,
                Ok(event) => {
                    if let Some(sid) = event.session_id.as_deref() {
                        if sid != accepted.session_id {
                            continue;
                        }
                    }
                    if event.event_type == "error"
                        || matches!(event.state.as_ref(), Some(AppState::Error))
                    {
                        eprintln!(
                            "execution failed: {}",
                            event
                                .error_message
                                .unwrap_or_else(|| "unknown error".to_string())
                        );
                        return 1;
                    }
                    let terminal = matches!(event.state.as_ref(), Some(AppState::Results))
                        || event.event_type == "capability_result";
                    if !terminal {
                        continue;
                    }
                    let execution_id = event
                        .execution_id
                        .or(accepted.execution_id.clone())
                        .unwrap_or_default();
                    let output = event.output.unwrap_or(DocApprovalOutput {
                        doc_type: String::new(),
                        parties: vec![],
                        amounts: vec![],
                        confidence: 0.0,
                        recommendation: String::new(),
                    });
                    let trace = if execution_id.is_empty() {
                        Vec::new()
                    } else {
                        client
                            .fetch_trace(base_url, workspace, &execution_id)
                            .await
                            .unwrap_or_default()
                    };
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
                Err(err) => {
                    eprintln!("event stream failed: {err}");
                    return 1;
                }
            }
        }

        eprintln!("event stream ended before result");
        1
    })
}
