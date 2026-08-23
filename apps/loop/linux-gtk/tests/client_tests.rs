use loop_core_rs::{
    ActionItem, Decision, LoopOutput, TestEmbeddedRuntime,
};

#[test]
fn embedded_submit_returns_output() {
    let mut host = TestEmbeddedRuntime::new(LoopOutput {
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
    });
    let result = host.submit_transcript("transcript").expect("submit");
    assert_eq!(result.output.summary, "We agreed to ship Wave 1.");
    assert_eq!(result.output.action_items[0].task, "Send notes");
}
