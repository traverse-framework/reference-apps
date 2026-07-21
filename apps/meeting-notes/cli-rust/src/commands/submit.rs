use meeting_notes_core_rs::{
    EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
};

use crate::output::{print_submit_result, SubmitResultJson};

pub fn execute(transcript: &str, json: bool) -> i32 {
    let mut host = match EmbeddedRuntime::init_default() {
        Ok(host) => host,
        Err(err) => {
            eprintln!("{err}");
            eprintln!(
                "hint: set MEETING_NOTES_MANIFEST to manifests/meeting-notes/app.manifest.json"
            );
            return 1;
        }
    };
    let code = finish(host.submit_transcript(transcript), json);
    host.shutdown();
    code
}

pub fn execute_with_host(host: &mut TestEmbeddedRuntime, transcript: &str, json: bool) -> i32 {
    finish(host.submit_transcript(transcript), json)
}

fn finish(result: Result<HostRunResult, HostError>, json: bool) -> i32 {
    match result {
        Ok(result) => {
            print_submit_result(
                &SubmitResultJson {
                    execution_id: result.session_id,
                    output: result.output,
                    trace: result.events,
                },
                json,
            );
            0
        }
        Err(err) => {
            eprintln!("{err}");
            1
        }
    }
}
