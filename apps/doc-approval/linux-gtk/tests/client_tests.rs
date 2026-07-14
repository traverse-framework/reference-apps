use doc_approval_core_rs::{DocApprovalOutput, TestEmbeddedRuntime};

#[test]
fn embedded_submit_returns_output() {
    let mut host = TestEmbeddedRuntime::new(DocApprovalOutput {
        doc_type: "invoice".to_string(),
        parties: vec![],
        amounts: vec![],
        confidence: 0.5,
        recommendation: "review".to_string(),
    });
    let result = host.submit_document("doc").expect("submit");
    assert_eq!(result.output.recommendation, "review");
}
