use serde_json::json;
use traverse_core_rs::{
    ProcessOutput, StateEvent, SummarizeOutput, TestEmbeddedRuntime, TraverseStarterOutput,
    ValidateOutput, DEFAULT_WORKFLOW_ID, RUNTIME_MODE_EMBEDDED,
};

fn sample_output() -> TraverseStarterOutput {
    TraverseStarterOutput {
        validate: ValidateOutput {
            valid: true,
            issues: vec![],
        },
        process: ProcessOutput {
            title: "Title".to_string(),
            tags: vec!["tag".to_string()],
            note_type: "meeting".to_string(),
            suggested_next_action: "follow up".to_string(),
            status: "processed".to_string(),
        },
        summarize: SummarizeOutput {
            summary: "A short summary".to_string(),
            word_count: 3,
        },
    }
}

#[test]
fn test_double_submit_note_returns_scripted_output() {
    let mut host = TestEmbeddedRuntime::new(sample_output());
    assert_eq!(host.workflow_id(), DEFAULT_WORKFLOW_ID);
    let result = host.submit_note("hello world").expect("submit");
    assert_eq!(result.output.process.title, "Title");
    assert_eq!(result.output.summarize.word_count, 3);
    assert!(!result.events.is_empty());
}

#[test]
fn test_double_error_surfaces_execution_failure() {
    let mut host = TestEmbeddedRuntime::with_error("execution_failed", "boom");
    let err = host.submit_note("x").expect_err("should fail");
    assert!(err.to_string().contains("boom"));
}

#[test]
fn state_event_from_embedder_envelope() {
    let event = json!({
        "kind": "embedder_event",
        "event_type": "capability_result",
        "session_id": "sess-1",
        "data": {
            "status": "completed",
            "output": {
                "validate": { "valid": true, "issues": [] },
                "process": {
                    "title": "T",
                    "tags": [],
                    "noteType": "n",
                    "suggestedNextAction": "x",
                    "status": "done"
                },
                "summarize": { "summary": "Summary", "wordCount": 1 }
            }
        }
    });
    let parsed = StateEvent::from_embedder_event(&event).unwrap();
    assert_eq!(parsed.session_id.as_deref(), Some("sess-1"));
    assert_eq!(parsed.output.unwrap().process.title, "T");
}

#[test]
fn runtime_mode_constant_is_embedded() {
    assert_eq!(RUNTIME_MODE_EMBEDDED, "Embedded");
}

#[test]
fn state_event_from_sse_still_works() {
    let event = StateEvent::from_sse(
        "capability_result",
        r#"{"state":"results","output":{"validate":{"valid":true,"issues":[]},"process":{"title":"T","tags":[],"noteType":"n","suggestedNextAction":"x","status":"done"},"summarize":{"summary":"Summary","wordCount":1}}}"#,
    )
    .unwrap();
    assert_eq!(event.output.unwrap().process.title, "T");
}
