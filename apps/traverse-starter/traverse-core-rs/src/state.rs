use serde::Deserialize;
use serde_json::Value;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AppState {
    Idle,
    Processing,
    Results,
    Error,
    Other(String),
}

impl AppState {
    pub fn from_runtime(name: &str) -> Self {
        match name {
            "idle" => Self::Idle,
            "processing" => Self::Processing,
            "results" => Self::Results,
            "error" => Self::Error,
            other => Self::Other(other.to_string()),
        }
    }

    pub fn as_str(&self) -> &str {
        match self {
            Self::Idle => "idle",
            Self::Processing => "processing",
            Self::Results => "results",
            Self::Error => "error",
            Self::Other(s) => s.as_str(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct StateEvent {
    pub event_type: String,
    pub state: Option<AppState>,
    pub session_id: Option<String>,
    pub execution_id: Option<String>,
    pub output: Option<crate::TraverseStarterOutput>,
    pub error_message: Option<String>,
    pub raw: Value,
}

#[derive(Debug, Deserialize)]
pub(crate) struct EventPayload {
    pub state: Option<String>,
    pub session_id: Option<String>,
    pub execution_id: Option<String>,
    pub output: Option<crate::TraverseStarterOutput>,
    pub error: Option<Value>,
}

impl StateEvent {
    pub fn from_sse(event_type: &str, data: &str) -> Option<Self> {
        if event_type == "heartbeat" {
            return Some(Self {
                event_type: event_type.to_string(),
                state: None,
                session_id: None,
                execution_id: None,
                output: None,
                error_message: None,
                raw: Value::Null,
            });
        }
        let raw: Value = serde_json::from_str(data).ok()?;
        let payload: EventPayload = serde_json::from_value(raw.clone()).ok()?;
        let error_message = match payload.error {
            Some(Value::String(s)) => Some(s),
            Some(Value::Object(map)) => map
                .get("message")
                .and_then(|v| v.as_str())
                .map(str::to_string),
            _ => None,
        };
        Some(Self {
            event_type: event_type.to_string(),
            state: payload.state.as_deref().map(AppState::from_runtime),
            session_id: payload.session_id,
            execution_id: payload.execution_id,
            output: payload.output,
            error_message,
            raw,
        })
    }
}
