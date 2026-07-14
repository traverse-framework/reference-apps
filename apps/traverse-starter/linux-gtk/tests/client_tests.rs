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
fn embedded_submit_returns_output() {
    let mut host = TestEmbeddedRuntime::new(sample_output());
    let result = host.submit_note("hello").expect("submit");
    assert_eq!(result.output.process.title, "Title");
}
