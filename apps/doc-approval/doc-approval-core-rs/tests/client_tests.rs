use doc_approval_core_rs::{DocApprovalClient, ServerDiscovery, StateEvent};
use serde_json::json;
use wiremock::matchers::{method, path, query_param};
use wiremock::{Mock, MockServer, ResponseTemplate};

#[tokio::test]
async fn health_check_ok() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/healthz"))
        .respond_with(ResponseTemplate::new(200))
        .mount(&server)
        .await;
    let client = DocApprovalClient::new();
    assert!(client.health_check(&server.uri()).await.unwrap());
}

#[tokio::test]
async fn send_command_posts_to_apps_commands() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/v1/workspaces/local-default/apps/doc-approval/commands"))
        .respond_with(ResponseTemplate::new(202).set_body_json(json!({
            "api_version": "v1",
            "status": "accepted",
            "workspace_id": "local-default",
            "app_id": "doc-approval",
            "session_id": "sess-1",
            "command": "submit",
            "state": "processing",
            "execution_id": "exec-1"
        })))
        .mount(&server)
        .await;

    let client = DocApprovalClient::new();
    let accepted = client
        .submit_document(&server.uri(), "local-default", "hello")
        .await
        .unwrap();
    assert_eq!(accepted.session_id, "sess-1");
}

#[tokio::test]
async fn list_sessions_parses_pending_review() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/v1/workspaces/local-default/apps/doc-approval/sessions"))
        .and(query_param("state", "pending_review"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "sessions": [{"session_id":"s1","state":"pending_review","title":"Contract"}]
        })))
        .mount(&server)
        .await;

    let client = DocApprovalClient::new();
    let sessions = client
        .list_sessions(&server.uri(), "local-default", Some("pending_review"))
        .await
        .unwrap();
    assert_eq!(sessions.len(), 1);
    assert_eq!(sessions[0].title.as_deref(), Some("Contract"));
}

#[tokio::test]
async fn send_command_for_session_includes_session_id() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/v1/workspaces/local-default/apps/doc-approval/commands"))
        .respond_with(ResponseTemplate::new(202).set_body_json(json!({
            "api_version": "v1",
            "status": "accepted",
            "workspace_id": "local-default",
            "app_id": "doc-approval",
            "session_id": "sess-approve",
            "command": "approve",
            "state": "approved"
        })))
        .mount(&server)
        .await;

    let client = DocApprovalClient::new();
    let accepted = client
        .send_command_for_session(
            &server.uri(),
            "local-default",
            "sess-approve",
            "approve",
            &json!({}),
        )
        .await
        .unwrap();
    assert_eq!(accepted.command, "approve");
}

#[test]
fn server_discovery_reads_json() {
    let mut path = std::env::temp_dir();
    path.push(format!("doc-approval-core-rs-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&path);
    std::fs::create_dir_all(path.join(".traverse")).unwrap();
    std::fs::write(
        path.join(".traverse/server.json"),
        r#"{"base_url":"http://127.0.0.1:9999","workspace_default":"ws-a"}"#,
    )
    .unwrap();
    let info = ServerDiscovery::from_file(path.join(".traverse/server.json")).unwrap();
    assert_eq!(info.base_url, "http://127.0.0.1:9999");
}

#[test]
fn state_event_from_sse() {
    let event = StateEvent::from_sse(
        "capability_result",
        r#"{"state":"results","output":{"analysis":{"docType":"nda","parties":[],"amounts":[],"confidence":0.5,"recommendation":"review"},"recommendation":{"recommendation":"review","rationale":"needs human","confidence":"medium"}}}"#,
    )
    .unwrap();
    assert_eq!(event.output.unwrap().analysis.doc_type, "nda");
}
