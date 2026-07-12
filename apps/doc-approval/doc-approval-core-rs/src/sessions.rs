use serde::Deserialize;
use serde_json::Value;

use crate::client::{normalize_base_url, DocApprovalClientError};

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub struct SessionSummary {
    pub session_id: String,
    pub state: String,
    pub title: Option<String>,
}

pub async fn list_sessions(
    http: &reqwest::Client,
    base_url: &str,
    workspace_id: &str,
    app_id: &str,
    state: Option<&str>,
) -> Result<Vec<SessionSummary>, DocApprovalClientError> {
    let mut url = format!(
        "{}/v1/workspaces/{}/apps/{}/sessions",
        normalize_base_url(base_url),
        workspace_id,
        app_id
    );
    if let Some(state) = state {
        url.push_str(&format!("?state={state}"));
    }
    let response = http
        .get(&url)
        .send()
        .await
        .map_err(|e| DocApprovalClientError::Request(e.to_string()))?;
    if !response.status().is_success() {
        return Err(DocApprovalClientError::Http(response.status().as_u16()));
    }
    let raw: Value = response
        .json()
        .await
        .map_err(|_| DocApprovalClientError::Decode)?;
    Ok(parse_sessions(&raw))
}

pub fn parse_sessions(raw: &Value) -> Vec<SessionSummary> {
    let items = if let Some(arr) = raw.as_array() {
        arr.clone()
    } else if let Some(arr) = raw.get("sessions").and_then(|v| v.as_array()) {
        arr.clone()
    } else {
        return Vec::new();
    };
    items
        .into_iter()
        .filter_map(|item| {
            let session_id = item
                .get("session_id")
                .or_else(|| item.get("id"))
                .and_then(|v| v.as_str())?
                .to_string();
            let state = item.get("state")?.as_str()?.to_string();
            let title = item
                .get("title")
                .and_then(|v| v.as_str())
                .map(str::to_string);
            Some(SessionSummary {
                session_id,
                state,
                title,
            })
        })
        .collect()
}
