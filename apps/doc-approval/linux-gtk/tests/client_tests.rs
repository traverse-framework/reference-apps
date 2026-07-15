use doc_approval_core_rs::{
    AnalysisOutput, DocApprovalOutput, RecommendationOutput, TestEmbeddedRuntime,
};

#[test]
fn embedded_submit_returns_output() {
    let mut host = TestEmbeddedRuntime::new(DocApprovalOutput {
        analysis: AnalysisOutput {
            doc_type: "invoice".to_string(),
            parties: vec![],
            amounts: vec![],
            confidence: "0.5".to_string(),
            recommendation: "review".to_string(),
        },
        recommendation: RecommendationOutput {
            recommendation: "review".to_string(),
            rationale: "Needs human review".to_string(),
            confidence: "medium".to_string(),
        },
    });
    let result = host.submit_document("doc").expect("submit");
    assert_eq!(result.output.recommendation.recommendation, "review");
}
