use doc_approval_core_rs::{
    AnalysisOutput, DocApprovalOutput, RecommendationOutput, TestEmbeddedRuntime,
};

fn sample() -> DocApprovalOutput {
    DocApprovalOutput {
        analysis: AnalysisOutput {
            doc_type: "invoice".into(),
            parties: vec!["Acme".into()],
            amounts: vec!["$100".into()],
            confidence: "0.9".into(),
            recommendation: "approve".into(),
        },
        recommendation: RecommendationOutput {
            recommendation: "approve".into(),
            rationale: "Amounts within policy".into(),
            confidence: "high".into(),
        },
    }
}

#[test]
fn test_double_submits_pipeline_output() {
    let mut host = TestEmbeddedRuntime::new(sample());
    let result = host.submit_document("Invoice").expect("submit");
    assert_eq!(result.output.recommendation.recommendation, "approve");
    assert_eq!(result.output.analysis.doc_type, "invoice");
}
