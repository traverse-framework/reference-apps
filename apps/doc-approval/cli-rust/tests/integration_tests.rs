use doc_approval_cli::client::TraverseClient;
use doc_approval_cli::commands;

#[tokio::test]
async fn check_health_returns_true_on_200() {
    let mut server = mockito::Server::new_async().await;
    let _mock = server
        .mock("GET", "/healthz")
        .with_status(200)
        .create_async()
        .await;

    let client = TraverseClient::new();
    assert!(client.check_health(&server.url()).await.unwrap());
}

#[test]
fn submit_flow_succeeds_against_mock_server() {
    let mut server = mockito::Server::new();

    let _submit = server
        .mock(
            "POST",
            "/v1/workspaces/local-default/apps/doc-approval/commands",
        )
        .with_status(202)
        .with_header("content-type", "application/json")
        .with_body(
            r#"{"api_version":"v1","status":"accepted","workspace_id":"local-default","app_id":"doc-approval","session_id":"sess-1","command":"submit","state":"processing","execution_id":"exec_abc"}"#,
        )
        .create();

    let sse_body = "event: capability_result\ndata: {\"state\":\"results\",\"session_id\":\"sess-1\",\"execution_id\":\"exec_abc\",\"output\":{\"docType\":\"nda\",\"parties\":[\"A\"],\"amounts\":[],\"confidence\":0.9,\"recommendation\":\"approve\"}}\n\n";
    let _events = server
        .mock(
            "GET",
            "/v1/workspaces/local-default/apps/doc-approval/events",
        )
        .with_status(200)
        .with_header("content-type", "text/event-stream")
        .with_body(sse_body)
        .create();

    let _trace = server
        .mock("GET", "/v1/workspaces/local-default/traces/exec_abc")
        .with_status(200)
        .with_body("[]")
        .create();

    let code = commands::submit::execute(&server.url(), "local-default", "contract text", true);
    assert_eq!(code, 0);
}

#[test]
fn health_command_reports_online() {
    let mut server = mockito::Server::new();
    let _mock = server
        .mock("GET", "/healthz")
        .with_status(200)
        .create();

    let code = commands::health::execute(&server.url(), true);
    assert_eq!(code, 0);
}
