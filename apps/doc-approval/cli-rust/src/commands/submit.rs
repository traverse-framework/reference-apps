use doc_approval_core_rs::{
    EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
};

use crate::output::{print_submit_result, SubmitResultJson};

pub fn execute(document: &str, json: bool) -> i32 {
    let mut host = match EmbeddedRuntime::init_default() {
        Ok(host) => host,
        Err(err) => {
            eprintln!("{err}");
            eprintln!(
                "hint: doc-approval bundle manifests are tracked in reference-apps #112; set DOC_APPROVAL_MANIFEST when available"
            );
            return 1;
        }
    };
    let code = finish(host.submit_document(document), json);
    host.shutdown();
    code
}

pub fn execute_with_host(host: &mut TestEmbeddedRuntime, document: &str, json: bool) -> i32 {
    finish(host.submit_document(document), json)
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
