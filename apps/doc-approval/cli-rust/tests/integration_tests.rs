use doc_approval_cli::client::TraverseClient;
use doc_approval_cli::commands;

#[test]
fn check_health_returns_true_on_200() {
    let mut server = mockito::Server::new();
    let _mock = server
        .mock("GET", "/healthz")
        .with_status(200)
        .create();

    let client = TraverseClient::new();
    assert!(client.check_health(&server.url()).unwrap());
}

#[test]
fn submit_flow_succeeds_against_mock_server() {
    let mut server = mockito::Server::new();

    let _execute = server
        .mock("POST", "/v1/workspaces/local-default/execute")
        .with_status(200)
        .with_body(r#"{"execution_id":"exec_abc"}"#)
        .create();

    let _poll = server
        .mock("GET", "/v1/workspaces/local-default/executions/exec_abc")
        .with_status(200)
        .with_body(
            r#"{"status":"succeeded","output":{"docType":"invoice","parties":["A"],"amounts":["$100"],"confidence":0.9,"recommendation":"approve"}}"#,
        )
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
