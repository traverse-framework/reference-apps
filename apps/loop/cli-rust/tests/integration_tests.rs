use loop_cli::commands;
use loop_core_rs::{
    ActionItem, Decision, LoopOutput, TestEmbeddedRuntime,
};

fn sample_output() -> LoopOutput {
    LoopOutput {
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
fn submit_flow_succeeds_with_test_double() {
    let mut host = TestEmbeddedRuntime::new(sample_output());
    let code = commands::submit::execute_with_host(&mut host, "hello", true);
    assert_eq!(code, 0);
}

#[test]
fn health_command_reports_embedded_ready() {
    let host = TestEmbeddedRuntime::new(sample_output());
    let code = commands::health::execute_with_host(&host, true);
    assert_eq!(code, 0);
}
