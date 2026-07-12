use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::sse;
use crate::state::StateEvent;
use crate::{list_sessions, SessionSummary, DEFAULT_APP_ID};

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct DocApprovalOutput {
    #[serde(rename = "docType")]
    pub doc_type: String,
    pub parties: Vec<String>,
    pub amounts: Vec<String>,
    pub confidence: f64,
    pub recommendation: String,
}

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct TraceEvent {
    pub event_type: String,
    pub timestamp: String,
    pub data: Option<Value>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct CommandAccepted {
    pub api_version: String,
    pub status: String,
    pub workspace_id: String,
    pub app_id: String,
    pub session_id: String,
    pub command: String,
    pub state: String,
    pub execution_id: Option<String>,
}

#[derive(Debug, PartialEq, Eq)]
pub enum DocApprovalClientError {
    Http(u16),
    Decode,
    Request(String),
}

impl std::fmt::Display for DocApprovalClientError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Http(code) => write!(f, "HTTP {code}"),
            Self::Decode => write!(f, "decode failed"),
            Self::Request(msg) => write!(f, "request failed: {msg}"),
        }
    }
}

impl std::error::Error for DocApprovalClientError {}

#[derive(Clone)]
pub struct DocApprovalClient {
    http: reqwest::Client,
}

impl Default for DocApprovalClient {
    fn default() -> Self {
        Self::new()
    }
}

impl DocApprovalClient {
    pub fn new() -> Self {
        Self {
            http: reqwest::Client::new(),
        }
    }

    pub fn with_client(http: reqwest::Client) -> Self {
        Self { http }
    }

    pub async fn health_check(&self, base_url: &str) -> Result<bool, DocApprovalClientError> {
        let url = format!("{}/healthz", normalize_base_url(base_url));
        let response = self
            .http
            .get(url)
            .send()
            .await
            .map_err(|e| DocApprovalClientError::Request(e.to_string()))?;
        Ok(response.status().is_success())
    }

    pub async fn check_health(&self, base_url: &str) -> Result<bool, DocApprovalClientError> {
        self.health_check(base_url).await
    }

    pub async fn send_command(
        &self,
        base_url: &str,
        workspace_id: &str,
        app_id: &str,
        command: &str,
        payload: &Value,
        session_id: Option<&str>,
    ) -> Result<CommandAccepted, DocApprovalClientError> {
        let url = format!(
            "{}/v1/workspaces/{}/apps/{}/commands",
            normalize_base_url(base_url),
            workspace_id,
            app_id
        );
        let mut body = json!({
            "command": command,
            "payload": payload,
        });
        if let Some(session_id) = session_id {
            body["session_id"] = Value::String(session_id.to_string());
        }
        let response = self
            .http
            .post(url)
            .json(&body)
            .send()
            .await
            .map_err(|e| DocApprovalClientError::Request(e.to_string()))?;
        if !(200..300).contains(&response.status().as_u16()) {
            return Err(DocApprovalClientError::Http(response.status().as_u16()));
        }
        let payload: CommandAcceptedResponse = response
            .json()
            .await
            .map_err(|_| DocApprovalClientError::Decode)?;
        Ok(CommandAccepted {
            api_version: payload.api_version,
            status: payload.status,
            workspace_id: payload.workspace_id,
            app_id: payload.app_id,
            session_id: payload.session_id,
            command: payload.command,
            state: payload.state,
            execution_id: payload.execution_id,
        })
    }

    /// Session-scoped command dispatch (issue DoD).
    pub async fn send_command_for_session(
        &self,
        base_url: &str,
        workspace_id: &str,
        session_id: &str,
        command: &str,
        payload: &Value,
    ) -> Result<CommandAccepted, DocApprovalClientError> {
        self.send_command(
            base_url,
            workspace_id,
            DEFAULT_APP_ID,
            command,
            payload,
            Some(session_id),
        )
        .await
    }

    pub async fn submit_document(
        &self,
        base_url: &str,
        workspace_id: &str,
        document: &str,
    ) -> Result<CommandAccepted, DocApprovalClientError> {
        self.send_command(
            base_url,
            workspace_id,
            DEFAULT_APP_ID,
            "submit",
            &json!({ "document": document }),
            None,
        )
        .await
    }

    pub async fn list_sessions(
        &self,
        base_url: &str,
        workspace_id: &str,
        state: Option<&str>,
    ) -> Result<Vec<SessionSummary>, DocApprovalClientError> {
        list_sessions(&self.http, base_url, workspace_id, DEFAULT_APP_ID, state).await
    }

    pub async fn fetch_trace(
        &self,
        base_url: &str,
        workspace_id: &str,
        execution_id: &str,
    ) -> Result<Vec<TraceEvent>, DocApprovalClientError> {
        let url = format!(
            "{}/v1/workspaces/{}/traces/{}",
            normalize_base_url(base_url),
            workspace_id,
            execution_id
        );
        let response = self
            .http
            .get(url)
            .send()
            .await
            .map_err(|e| DocApprovalClientError::Request(e.to_string()))?;
        if !response.status().is_success() {
            return Err(DocApprovalClientError::Http(response.status().as_u16()));
        }
        response
            .json()
            .await
            .map_err(|_| DocApprovalClientError::Decode)
    }

    pub fn app_events_url(base_url: &str, workspace_id: &str, app_id: &str) -> String {
        format!(
            "{}/v1/workspaces/{}/apps/{}/events",
            normalize_base_url(base_url),
            workspace_id,
            app_id
        )
    }

    pub async fn subscribe_events(
        &self,
        base_url: &str,
        workspace_id: &str,
        app_id: &str,
    ) -> Result<
        impl futures_util::Stream<Item = Result<StateEvent, DocApprovalClientError>>,
        DocApprovalClientError,
    > {
        sse::subscribe_events(&self.http, base_url, workspace_id, app_id).await
    }
}

pub fn normalize_base_url(base_url: &str) -> String {
    base_url.trim().trim_end_matches('/').to_string()
}

#[derive(Debug, Deserialize)]
struct CommandAcceptedResponse {
    api_version: String,
    status: String,
    workspace_id: String,
    app_id: String,
    session_id: String,
    command: String,
    state: String,
    execution_id: Option<String>,
}
