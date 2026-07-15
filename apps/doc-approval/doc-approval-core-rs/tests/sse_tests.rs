use doc_approval_core_rs::StateEvent;

#[test]
fn parses_capability_result_payload() {
    let event = StateEvent::from_sse(
        "capability_result",
        r#"{"state":"results","session_id":"s1","execution_id":"e1","output":{"analysis":{"docType":"nda","parties":["A"],"amounts":[],"confidence":0.9,"recommendation":"approve"},"recommendation":{"recommendation":"approve","rationale":"Policy match","confidence":"high"}}}"#,
    )
    .expect("event");
    assert_eq!(event.event_type, "capability_result");
    assert_eq!(
        event
            .output
            .as_ref()
            .map(|o| o.recommendation.recommendation.as_str()),
        Some("approve")
    );
    assert_eq!(
        event.output.as_ref().map(|o| o.analysis.confidence.as_str()),
        Some("0.9")
    );
}
