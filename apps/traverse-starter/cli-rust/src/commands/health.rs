use traverse_core_rs::{
    TestEmbeddedRuntime, DEFAULT_WORKFLOW_ID, RUNTIME_MODE_EMBEDDED,
};

use crate::output::print_json;

/// Production health: embedded runtime is ready when the bundle initializes.
pub fn execute(json: bool) -> i32 {
    match traverse_core_rs::EmbeddedRuntime::init_default() {
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
    debug_assert_eq!(workflow, DEFAULT_WORKFLOW_ID);
}
