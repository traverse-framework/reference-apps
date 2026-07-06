use traverse_starter_cli::client::TraverseClient;
use traverse_starter_cli::commands;

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
fn run_flow_succeeds_against_mock_server() {
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
            r#"{"status":"succeeded","output":{"title":"Title","tags":["tag"],"noteType":"meeting","suggestedNextAction":"follow up","status":"processed"}}"#,
        )
        .create();

    let _trace = server
        .mock("GET", "/v1/workspaces/local-default/traces/exec_abc")
        .with_status(200)
        .with_body("[]")
        .create();

    let code = commands::run::execute(&server.url(), "local-default", "hello world", true);
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
