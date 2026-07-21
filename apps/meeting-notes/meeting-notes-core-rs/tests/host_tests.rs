use meeting_notes_core_rs::{
    ActionItem, Decision, MeetingNotesOutput, TestEmbeddedRuntime, DEFAULT_WORKFLOW_ID,
    RUNTIME_MODE_EMBEDDED,
};

fn sample_output() -> MeetingNotesOutput {
    MeetingNotesOutput {
        action_items: vec![ActionItem {
            task: "Send notes".into(),
            owner: Some("Alex".into()),
            due: None,
        }],
        decisions: vec![Decision {
            text: "Ship Wave 1".into(),
            made_by: Some("Team".into()),
        }],
        follow_ups: vec!["Schedule review".into()],
        summary: "We agreed to ship Wave 1.".into(),
    }
}

#[test]
fn runtime_mode_constant_is_embedded() {
    assert_eq!(RUNTIME_MODE_EMBEDDED, "Embedded");
    assert_eq!(DEFAULT_WORKFLOW_ID, "meeting-notes.process");
}

#[test]
fn test_double_submit_transcript_returns_scripted_output() {
    let mut host = TestEmbeddedRuntime::new(sample_output());
    let result = host
        .submit_transcript("Alex will send notes. Team decided to ship Wave 1.")
        .expect("submit");
    assert_eq!(result.output.summary, "We agreed to ship Wave 1.");
    assert_eq!(result.output.action_items[0].task, "Send notes");
    assert_eq!(result.output.decisions[0].text, "Ship Wave 1");
}
