use traverse_core_rs::StateEvent;

#[test]
fn parses_heartbeat() {
    let event = StateEvent::from_sse("heartbeat", "").unwrap();
    assert_eq!(event.event_type, "heartbeat");
    assert!(event.output.is_none());
}

#[test]
fn parses_state_changed() {
    let event = StateEvent::from_sse(
        "state_changed",
        r#"{"state":"processing","session_id":"s1"}"#,
    )
    .unwrap();
    assert_eq!(event.state.unwrap().as_str(), "processing");
    assert_eq!(event.session_id.as_deref(), Some("s1"));
}

#[test]
fn parses_capability_result_payload() {
    let event = StateEvent::from_sse(
        "capability_result",
        r#"{"state":"results","session_id":"s1","execution_id":"e1","output":{"validate":{"valid":true,"issues":[]},"process":{"title":"Hello","tags":["a"],"noteType":"n","suggestedNextAction":"x","status":"done"},"summarize":{"summary":"A short summary","wordCount":3}}}"#,
    )
    .unwrap();
    assert_eq!(event.event_type, "capability_result");
    assert_eq!(event.execution_id.as_deref(), Some("e1"));
    assert_eq!(event.output.unwrap().process.title, "Hello");
}

#[test]
fn parses_error_object_message() {
    let event = StateEvent::from_sse(
        "error",
        r#"{"state":"error","error":{"message":"boom"}}"#,
    )
    .unwrap();
    assert_eq!(event.error_message.as_deref(), Some("boom"));
}
