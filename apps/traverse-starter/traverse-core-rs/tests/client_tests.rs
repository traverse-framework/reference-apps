use serde_json::json;
use traverse_core_rs::{ServerDiscovery, StateEvent, TraverseClient};
use wiremock::matchers::{method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

#[tokio::test]
async fn health_check_ok() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/healthz"))
        .respond_with(ResponseTemplate::new(200))
        .mount(&server)
        .await;
    let client = TraverseClient::new();
    assert!(client.health_check(&server.uri()).await.unwrap());
}

#[tokio::test]
async fn send_command_posts_to_apps_commands() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/v1/workspaces/local-default/apps/traverse-starter/commands"))
        .respond_with(ResponseTemplate::new(202).set_body_json(json!({
            "api_version": "v1",
            "status": "accepted",
            "workspace_id": "local-default",
            "app_id": "traverse-starter",
            "session_id": "sess-1",
            "command": "submit",
            "state": "processing",
            "execution_id": "exec-1"
        })))
        .mount(&server)
        .await;

    let client = TraverseClient::new();
    let accepted = client
        .submit_note(&server.uri(), "local-default", "hello")
        .await
        .unwrap();
    assert_eq!(accepted.session_id, "sess-1");
    assert_eq!(accepted.state, "processing");
}

#[test]
fn server_discovery_reads_json() {
    let dir = tempfile_dir();
    let traverse = dir.join(".traverse");
    std::fs::create_dir_all(&traverse).unwrap();
    std::fs::write(
        traverse.join("server.json"),
        r#"{"base_url":"http://127.0.0.1:9999","workspace_default":"ws-a"}"#,
    )
    .unwrap();
    let info = ServerDiscovery::from_file(traverse.join("server.json")).unwrap();
    assert_eq!(info.base_url, "http://127.0.0.1:9999");
    assert_eq!(info.workspace_default, "ws-a");
}

#[test]
fn state_event_from_sse() {
    let event = StateEvent::from_sse(
        "capability_result",
        r#"{"state":"results","output":{"title":"T","tags":[],"noteType":"n","suggestedNextAction":"x","status":"done"}}"#,
    )
    .unwrap();
    assert_eq!(event.output.unwrap().title, "T");
}

fn tempfile_dir() -> std::path::PathBuf {
    let mut path = std::env::temp_dir();
    path.push(format!("traverse-core-rs-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&path);
    std::fs::create_dir_all(&path).unwrap();
    path
}
