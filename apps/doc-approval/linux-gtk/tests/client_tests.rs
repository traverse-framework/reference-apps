use doc_approval_gtk::client::TraverseClient;
use doc_approval_gtk::CAPABILITY_ID;
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
async fn execute_returns_execution_id() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .respond_with(ResponseTemplate::new(200).set_body_json(serde_json::json!({
            "execution_id": "exec_abc"
        })))
        .mount(&server)
        .await;

    let client = TraverseClient::new();
    let id = client
        .execute(
            &server.uri(),
            "local-default",
            CAPABILITY_ID,
            &serde_json::json!({ "document": "contract" }),
        )
        .await
        .unwrap();
    assert_eq!(id, "exec_abc");
}

#[tokio::test]
async fn poll_execution_parses_output() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .respond_with(ResponseTemplate::new(200).set_body_json(serde_json::json!({
            "status": "succeeded",
            "output": {
                "docType": "invoice",
                "parties": ["A", "B"],
                "amounts": ["$100"],
                "confidence": 0.9,
                "recommendation": "approve"
            }
        })))
        .mount(&server)
        .await;

    let client = TraverseClient::new();
    let result = client
        .poll_execution(&server.uri(), "local-default", "exec_abc")
        .await
        .unwrap();
    assert_eq!(result.status, "succeeded");
    assert_eq!(result.output.unwrap().doc_type, "invoice");
}
