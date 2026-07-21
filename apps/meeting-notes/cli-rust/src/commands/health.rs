use meeting_notes_core_rs::{
    EmbeddedRuntime, TestEmbeddedRuntime, RUNTIME_MODE_EMBEDDED,
};

use crate::output::print_json;

pub fn execute(json: bool) -> i32 {
    match EmbeddedRuntime::init_default() {
        Ok(mut host) => {
            print_health(json, true, host.workspace_id(), host.workflow_id());
            host.shutdown();
            0
        }
        Err(err) => {
            if json {
                print_json(&serde_json::json!({
                    "runtime_mode": RUNTIME_MODE_EMBEDDED,
                    "status": "Unavailable",
                    "error": err.to_string(),
                }));
            } else {
                eprintln!("Embedded runtime unavailable: {err}");
            }
            1
        }
    }
}

pub fn execute_with_host(host: &TestEmbeddedRuntime, json: bool) -> i32 {
    print_health(json, true, host.workspace_id(), host.workflow_id());
    0
}

fn print_health(json: bool, ready: bool, workspace: &str, workflow: &str) {
    let status = if ready { "Ready" } else { "Unavailable" };
    if json {
        print_json(&serde_json::json!({
            "runtime_mode": RUNTIME_MODE_EMBEDDED,
            "status": status,
            "workspace": workspace,
            "workflow": workflow,
        }));
    } else {
        println!(
            "{RUNTIME_MODE_EMBEDDED} · {status} · workspace={workspace} · workflow={workflow}"
        );
    }
}
