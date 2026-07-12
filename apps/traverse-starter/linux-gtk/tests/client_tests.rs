use traverse_starter_gtk::client::TraverseClient;
use wiremock::matchers::{method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

#[tokio::test]
async fn check_health_returns_true_on_200() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/healthz"))
        .respond_with(ResponseTemplate::new(200))
        .mount(&server)
        .await;

    let client = TraverseClient::new();
    assert!(client.check_health(&server.uri()).await.unwrap());
}

#[tokio::test]
async fn submit_note_posts_command() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/v1/workspaces/local-default/apps/traverse-starter/commands"))
        .respond_with(ResponseTemplate::new(202).set_body_json(serde_json::json!({
            "api_version": "v1",
            "status": "accepted",
            "workspace_id": "local-default",
            "app_id": "traverse-starter",
            "session_id": "sess-1",
            "command": "submit",
            "state": "processing",
            "execution_id": "exec_abc"
        })))
        .mount(&server)
        .await;

    let client = TraverseClient::new();
    let accepted = client
        .submit_note(&server.uri(), "local-default", "hello")
        .await
        .unwrap();
    assert_eq!(accepted.execution_id.as_deref(), Some("exec_abc"));
}
