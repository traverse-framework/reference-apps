use traverse_core_rs::{
    EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
};

use crate::output::{print_run_result, RunResultJson};

/// Runs against the production embedded host (bundle on disk).
pub fn execute(note: &str, json: bool) -> i32 {
    let mut host = match EmbeddedRuntime::init_default() {
        Ok(host) => host,
        Err(err) => {
            eprintln!("{err}");
            eprintln!(
                "hint: set TRAVERSE_STARTER_MANIFEST to manifests/traverse-starter/app.manifest.json"
            );
            return 1;
        }
    };
    let code = finish(host.submit_note(note), json);
    host.shutdown();
    code
}

/// Test helper using [`TestEmbeddedRuntime`] (no WASM / no bundle I/O).
pub fn execute_with_host(host: &mut TestEmbeddedRuntime, note: &str, json: bool) -> i32 {
    finish(host.submit_note(note), json)
}

fn finish(result: Result<HostRunResult, HostError>, json: bool) -> i32 {
    match result {
        Ok(result) => {
            print_run_result(
                &RunResultJson {
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
