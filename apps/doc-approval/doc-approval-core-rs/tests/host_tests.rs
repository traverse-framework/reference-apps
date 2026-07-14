use doc_approval_core_rs::{DocApprovalOutput, TestEmbeddedRuntime};

#[test]
fn test_double_submit_document_returns_scripted_output() {
    let mut host = TestEmbeddedRuntime::new(DocApprovalOutput {
        doc_type: "invoice".to_string(),
        parties: vec!["A".to_string()],
        amounts: vec!["$10".to_string()],
        confidence: 0.9,
        recommendation: "approve".to_string(),
    });
    let result = host.submit_document("hello").expect("submit");
    assert_eq!(result.output.doc_type, "invoice");
    assert_eq!(result.output.recommendation, "approve");
}
