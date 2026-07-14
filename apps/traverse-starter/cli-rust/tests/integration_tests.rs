use traverse_starter_cli::commands;
use traverse_core_rs::{
    ProcessOutput, SummarizeOutput, TestEmbeddedRuntime, TraverseStarterOutput, ValidateOutput,
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
fn run_flow_succeeds_with_test_double() {
    let mut host = TestEmbeddedRuntime::new(sample_output());
    let code = commands::run::execute_with_host(&mut host, "hello world", true);
    assert_eq!(code, 0);
}

#[test]
fn health_command_reports_embedded_ready() {
    let host = TestEmbeddedRuntime::new(sample_output());
    let code = commands::health::execute_with_host(&host, true);
    assert_eq!(code, 0);
}
