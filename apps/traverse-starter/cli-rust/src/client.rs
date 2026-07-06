use serde::Deserialize;
use serde_json::Value;

#[derive(Debug, Clone, PartialEq, Deserialize, serde::Serialize)]
pub struct TraverseStarterOutput {
    pub title: String,
    pub tags: Vec<String>,
    #[serde(rename = "noteType")]
    pub note_type: String,
    #[serde(rename = "suggestedNextAction")]
    pub suggested_next_action: String,
    pub status: String,
}

#[derive(Debug, Clone, PartialEq, Deserialize, serde::Serialize)]
pub struct TraceEvent {
    pub event_type: String,
    pub timestamp: String,
    pub data: Option<Value>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ExecutionPollResult {
    pub execution_id: String,
    pub status: String,
    pub output: Option<TraverseStarterOutput>,
    pub error: Option<String>,
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

pub struct TraverseClient {
    http: reqwest::blocking::Client,
}

impl Default for TraverseClient {
    fn default() -> Self {
        Self::new()
    }
}

impl TraverseClient {
    pub fn new() -> Self {
        Self {
            http: reqwest::blocking::Client::new(),
        }
    }

    pub fn with_client(http: reqwest::blocking::Client) -> Self {
        Self { http }
    }

    pub fn check_health(&self, base_url: &str) -> Result<bool, TraverseClientError> {
        let url = format!("{}/healthz", normalize_base_url(base_url));
        let response = self
            .http
            .get(url)
            .send()
            .map_err(|e| TraverseClientError::Request(e.to_string()))?;
        Ok(response.status().is_success())
    }

    pub fn execute(
        &self,
        base_url: &str,
        workspace_id: &str,
        capability: &str,
        input: &Value,
    ) -> Result<String, TraverseClientError> {
        let url = format!(
            "{}/v1/workspaces/{}/execute",
            normalize_base_url(base_url),
            workspace_id
        );
        let body = serde_json::json!({ "capability": capability, "input": input });
        let response = self
            .http
            .post(url)
            .json(&body)
            .send()
            .map_err(|e| TraverseClientError::Request(e.to_string()))?;
        if !response.status().is_success() {
            return Err(TraverseClientError::Http(response.status().as_u16()));
        }
        let payload: ExecuteResponse = response
            .json()
            .map_err(|_| TraverseClientError::Decode)?;
        Ok(payload.execution_id)
    }

    pub fn poll_execution(
        &self,
        base_url: &str,
        workspace_id: &str,
        execution_id: &str,
    ) -> Result<ExecutionPollResult, TraverseClientError> {
        let url = format!(
            "{}/v1/workspaces/{}/executions/{}",
            normalize_base_url(base_url),
            workspace_id,
            execution_id
        );
        let response = self
            .http
            .get(url)
            .send()
            .map_err(|e| TraverseClientError::Request(e.to_string()))?;
        if !response.status().is_success() {
            return Err(TraverseClientError::Http(response.status().as_u16()));
        }
        let payload: ExecutionPollResponse = response
            .json()
            .map_err(|_| TraverseClientError::Decode)?;
        Ok(ExecutionPollResult {
            execution_id: execution_id.to_string(),
            status: payload.status,
            output: payload.output,
            error: payload.error,
        })
    }

    pub fn fetch_trace(
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
            .map_err(|e| TraverseClientError::Request(e.to_string()))?;
        if !response.status().is_success() {
            return Err(TraverseClientError::Http(response.status().as_u16()));
        }
        response.json().map_err(|_| TraverseClientError::Decode)
    }
}

fn normalize_base_url(base_url: &str) -> String {
    base_url.trim().trim_end_matches('/').to_string()
}

#[derive(Debug, Deserialize)]
struct ExecuteResponse {
    execution_id: String,
}

#[derive(Debug, Deserialize)]
struct ExecutionPollResponse {
    status: String,
    output: Option<TraverseStarterOutput>,
    error: Option<String>,
}
