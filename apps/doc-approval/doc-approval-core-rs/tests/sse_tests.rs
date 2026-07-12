use doc_approval_core_rs::{parse_sessions, StateEvent};
use serde_json::json;

#[test]
fn parses_heartbeat() {
    let event = StateEvent::from_sse("heartbeat", "").unwrap();
    assert_eq!(event.event_type, "heartbeat");
}

#[test]
fn parses_capability_result_payload() {
    let event = StateEvent::from_sse(
        "capability_result",
        r#"{"state":"results","session_id":"s1","execution_id":"e1","output":{"docType":"nda","parties":["A"],"amounts":[],"confidence":0.9,"recommendation":"approve"}}"#,
    )
    .unwrap();
    assert_eq!(event.output.unwrap().recommendation, "approve");
}

#[test]
fn parses_sessions_wrapper() {
    let sessions = parse_sessions(&json!({
        "sessions": [{"session_id":"s1","state":"pending_review","title":"T"}]
    }));
    assert_eq!(sessions[0].session_id, "s1");
}
