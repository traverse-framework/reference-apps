//! Embedded Traverse runtime host for doc-approval shells.
//!
//! Production path uses [`BundleEmbedder`]. Bundle manifests land with
//! reference-apps #112; until then `EmbeddedRuntime::init_default` reports
//! Unavailable. Tests use [`EmbedderTestDouble`].

use serde_json::{json, Value};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use traverse_embedder::{
    BundleEmbedder, EmbedderConfig, EmbedderTestDouble, SecurityPosture, SubmitStatus,
    TraverseEmbedderApi,
};

use crate::client::{DocApprovalOutput, TraceEvent};
use crate::state::StateEvent;

pub const DEFAULT_WORKFLOW_ID: &str = "doc-approval.pipeline";
pub const RUNTIME_MODE_EMBEDDED: &str = "Embedded";
pub const MANIFEST_ENV: &str = "DOC_APPROVAL_MANIFEST";

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum HostError {
    Init(String),
    Rejected(String),
    Execution(String),
    Decode(String),
}

impl std::fmt::Display for HostError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Init(msg) => write!(f, "embedder init failed: {msg}"),
            Self::Rejected(msg) => write!(f, "submit rejected: {msg}"),
            Self::Execution(msg) => write!(f, "execution failed: {msg}"),
            Self::Decode(msg) => write!(f, "decode failed: {msg}"),
        }
    }
}

impl std::error::Error for HostError {}

#[derive(Debug, Clone, PartialEq)]
pub struct HostRunResult {
    pub session_id: String,
    pub output: DocApprovalOutput,
    pub events: Vec<TraceEvent>,
}

pub fn resolve_manifest_path(start: Option<&Path>) -> Option<PathBuf> {
    if let Ok(path) = std::env::var(MANIFEST_ENV) {
        let path = PathBuf::from(path);
        if path.is_file() {
            return Some(path);
        }
    }

    let mut dir = start
        .map(Path::to_path_buf)
        .or_else(|| std::env::current_dir().ok())?;
    loop {
        let candidate = dir
            .join("manifests")
            .join("doc-approval")
            .join("app.manifest.json");
        if candidate.is_file() {
            return Some(candidate);
        }
        if !dir.pop() {
            break;
        }
    }
    None
}

fn collect_submit<E: TraverseEmbedderApi>(
    embedder: &mut E,
    events: &Arc<Mutex<Vec<Value>>>,
    workflow_id: &str,
    input: &Value,
) -> Result<HostRunResult, HostError> {
    events.lock().expect("event sink").clear();
    let outcome = embedder.submit(workflow_id, input);
    if outcome.status == SubmitStatus::Rejected {
        let msg = outcome
            .error
            .map(|e| format!("{}: {}", e.code.as_str(), e.message))
            .unwrap_or_else(|| "submit rejected".to_string());
        return Err(HostError::Rejected(msg));
    }

    let session_id = outcome
        .session_id
        .clone()
        .unwrap_or_else(|| "sess-unknown".to_string());
    let raw_events = events.lock().expect("event sink").clone();
    let trace: Vec<TraceEvent> = raw_events
        .iter()
        .filter_map(|event| {
            let event_type = event.get("event_type")?.as_str()?.to_string();
            Some(TraceEvent {
                event_type,
                timestamp: event
                    .get("sequence")
                    .map(|s| s.to_string())
                    .unwrap_or_default(),
                data: event.get("data").cloned(),
            })
        })
        .collect();

    for event in &raw_events {
        let Some(parsed) = StateEvent::from_embedder_event(event) else {
            continue;
        };
        if parsed.session_id.as_deref().is_some_and(|s| s != session_id) {
            continue;
        }
        if parsed.event_type == "error"
            || matches!(parsed.state.as_ref(), Some(crate::AppState::Error))
        {
            return Err(HostError::Execution(
                parsed
                    .error_message
                    .unwrap_or_else(|| "execution failed".to_string()),
            ));
        }
        if parsed.event_type == "capability_result" {
            let output = parsed.output.unwrap_or(DocApprovalOutput {
                doc_type: String::new(),
                parties: vec![],
                amounts: vec![],
                confidence: 0.0,
                recommendation: String::new(),
            });
            return Ok(HostRunResult {
                session_id,
                output,
                events: trace,
            });
        }
    }

    Err(HostError::Execution(
        "embedder emitted no capability_result".to_string(),
    ))
}

fn attach_sink<E: TraverseEmbedderApi>(embedder: &mut E) -> Arc<Mutex<Vec<Value>>> {
    let events = Arc::new(Mutex::new(Vec::new()));
    let sink = events.clone();
    embedder.subscribe(Box::new(move |event| {
        sink.lock().expect("event sink").push(event.clone());
    }));
    events
}

pub struct EmbeddedRuntime {
    embedder: BundleEmbedder,
    events: Arc<Mutex<Vec<Value>>>,
    workspace_id: String,
    workflow_id: String,
}

impl EmbeddedRuntime {
    pub fn init(manifest_path: impl AsRef<Path>) -> Result<Self, HostError> {
        let mut config = EmbedderConfig::new(manifest_path.as_ref());
        config.security = SecurityPosture::Development;
        let workspace_id = config.workspace_id.clone();
        let mut embedder = BundleEmbedder::init(config).map_err(|e| {
            HostError::Init(format!("{}: {}", e.code.as_str(), e.message))
        })?;
        let events = attach_sink(&mut embedder);
        Ok(Self {
            embedder,
            events,
            workspace_id,
            workflow_id: DEFAULT_WORKFLOW_ID.to_string(),
        })
    }

    pub fn init_default() -> Result<Self, HostError> {
        let path = resolve_manifest_path(None).ok_or_else(|| {
            HostError::Init(format!(
                "could not find manifests/doc-approval/app.manifest.json (set {MANIFEST_ENV}; blocked on reference-apps #112)"
            ))
        })?;
        Self::init(path)
    }

    #[must_use]
    pub fn workspace_id(&self) -> &str {
        &self.workspace_id
    }

    #[must_use]
    pub fn workflow_id(&self) -> &str {
        &self.workflow_id
    }

    pub fn submit_document(&mut self, document: &str) -> Result<HostRunResult, HostError> {
        collect_submit(
            &mut self.embedder,
            &self.events,
            &self.workflow_id,
            &json!({ "document": document }),
        )
    }

    pub fn shutdown(&mut self) {
        let _ = self.embedder.shutdown();
    }
}

pub struct TestEmbeddedRuntime {
    embedder: EmbedderTestDouble,
    events: Arc<Mutex<Vec<Value>>>,
    workspace_id: String,
    workflow_id: String,
}

impl TestEmbeddedRuntime {
    #[must_use]
    pub fn new(output: DocApprovalOutput) -> Self {
        let mut embedder = EmbedderTestDouble::new(
            crate::DEFAULT_WORKSPACE,
            crate::DEFAULT_APP_ID,
            "1.0.0",
            std::env::consts::OS,
        )
        .with_target_output(DEFAULT_WORKFLOW_ID, serde_json::to_value(output).unwrap());
        let events = attach_sink(&mut embedder);
        Self {
            embedder,
            events,
            workspace_id: crate::DEFAULT_WORKSPACE.to_string(),
            workflow_id: DEFAULT_WORKFLOW_ID.to_string(),
        }
    }

    #[must_use]
    pub fn workspace_id(&self) -> &str {
        &self.workspace_id
    }

    #[must_use]
    pub fn workflow_id(&self) -> &str {
        &self.workflow_id
    }

    pub fn submit_document(&mut self, document: &str) -> Result<HostRunResult, HostError> {
        collect_submit(
            &mut self.embedder,
            &self.events,
            &self.workflow_id,
            &json!({ "document": document }),
        )
    }
}
