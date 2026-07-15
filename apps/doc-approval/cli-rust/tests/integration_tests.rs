use doc_approval_cli::commands;
use doc_approval_core_rs::{
    AnalysisOutput, DocApprovalOutput, RecommendationOutput, TestEmbeddedRuntime,
};

fn sample_output() -> DocApprovalOutput {
    DocApprovalOutput {
        analysis: AnalysisOutput {
            doc_type: "invoice".to_string(),
            parties: vec!["A".to_string()],
            amounts: vec!["$10".to_string()],
            confidence: "0.9".to_string(),
            recommendation: "approve".to_string(),
        },
        recommendation: RecommendationOutput {
            recommendation: "approve".to_string(),
            rationale: "Amounts within policy".to_string(),
            confidence: "high".to_string(),
        },
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
