use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::sse;
use crate::state::StateEvent;
use crate::DEFAULT_APP_ID;

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize)]
pub struct TraverseStarterOutput {
    pub title: String,
    pub tags: Vec<String>,
    #[serde(rename = "noteType")]
    pub note_type: String,
    #[serde(rename = "suggestedNextAction")]
    pub suggested_next_action: String,
    pub status: String,
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
pub enum TraverseClientError {
    Http(u16),
    Decode,
    Request(String),
}

impl std::fmt::Display for TraverseClientError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Http(code) => write!(f, "HTTP {code}"),
            Self::Decode => write!(f, "decode failed"),
            Self::Request(msg) => write!(f, "request failed: {msg}"),
        }
    }
}

impl std::error::Error for TraverseClientError {}

#[derive(Clone)]
pub struct TraverseClient {
    http: reqwest::Client,
}

impl Default for TraverseClient {
    fn default() -> Self {
        Self::new()
    }
}

impl TraverseClient {
    pub fn new() -> Self {
        Self {
            http: reqwest::Client::new(),
        }
    }

    pub fn with_client(http: reqwest::Client) -> Self {
        Self { http }
    }

    pub async fn health_check(&self, base_url: &str) -> Result<bool, TraverseClientError> {
        let url = format!("{}/healthz", normalize_base_url(base_url));
        let response = self
            .http
            .get(url)
            .send()
            .await
            .map_err(|e| TraverseClientError::Request(e.to_string()))?;
        Ok(response.status().is_success())
    }

    /// Alias matching older shells.
    pub async fn check_health(&self, base_url: &str) -> Result<bool, TraverseClientError> {
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
    ) -> Result<CommandAccepted, TraverseClientError> {
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
            .map_err(|e| TraverseClientError::Request(e.to_string()))?;
        if !(200..300).contains(&response.status().as_u16()) {
            return Err(TraverseClientError::Http(response.status().as_u16()));
        }
        let payload: CommandAcceptedResponse = response
            .json()
            .await
            .map_err(|_| TraverseClientError::Decode)?;
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

    pub async fn submit_note(
        &self,
        base_url: &str,
        workspace_id: &str,
        note: &str,
    ) -> Result<CommandAccepted, TraverseClientError> {
        self.send_command(
            base_url,
            workspace_id,
            DEFAULT_APP_ID,
            "submit",
            &json!({ "note": note }),
            None,
        )
        .await
    }

    pub async fn fetch_trace(
        &self,
        base_url: &str,
        workspace_id: &str,
        execution_id: &str,
    ) -> Result<Vec<TraceEvent>, TraverseClientError> {
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
            .map_err(|e| TraverseClientError::Request(e.to_string()))?;
        if !response.status().is_success() {
            return Err(TraverseClientError::Http(response.status().as_u16()));
        }
        response
            .json()
            .await
            .map_err(|_| TraverseClientError::Decode)
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
    ) -> Result<impl futures_util::Stream<Item = Result<StateEvent, TraverseClientError>>, TraverseClientError>
    {
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
