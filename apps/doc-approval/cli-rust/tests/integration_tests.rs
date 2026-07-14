use doc_approval_cli::commands;
use doc_approval_core_rs::{DocApprovalOutput, TestEmbeddedRuntime};

fn sample_output() -> DocApprovalOutput {
    DocApprovalOutput {
        doc_type: "invoice".to_string(),
        parties: vec!["A".to_string()],
        amounts: vec!["$10".to_string()],
        confidence: 0.9,
        recommendation: "approve".to_string(),
    }
}

#[test]
fn submit_flow_succeeds_with_test_double() {
    let mut host = TestEmbeddedRuntime::new(sample_output());
    let code = commands::submit::execute_with_host(&mut host, "hello", true);
    assert_eq!(code, 0);
}

#[test]
fn health_command_reports_embedded_ready() {
    let host = TestEmbeddedRuntime::new(sample_output());
    let code = commands::health::execute_with_host(&host, true);
    assert_eq!(code, 0);
}
