//! Embedded Traverse runtime host for traverse-starter shells.
//!
//! Production path uses [`BundleEmbedder`] from the public `traverse-embedder`
//! crate (spec 068). Tests use [`EmbedderTestDouble`] — never fake business
//! field computation in UI or shell code.

use serde_json::{json, Value};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use traverse_embedder::{
    BundleEmbedder, EmbedderConfig, EmbedderTestDouble, SecurityPosture, SubmitStatus,
    TraverseEmbedderApi,
};

use crate::client::{TraceEvent, TraverseStarterOutput};
use crate::state::StateEvent;

/// Workflow id invoked by traverse-starter shells.
pub const DEFAULT_WORKFLOW_ID: &str = "traverse-starter.pipeline";

/// Runtime mode label for Zone 1 (design-language).
pub const RUNTIME_MODE_EMBEDDED: &str = "Embedded";

/// Env var overriding the bundled `app.manifest.json` path.
pub const MANIFEST_ENV: &str = "TRAVERSE_STARTER_MANIFEST";

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

/// Successful embedded workflow run.
#[derive(Debug, Clone, PartialEq)]
pub struct HostRunResult {
    pub session_id: String,
    pub output: TraverseStarterOutput,
    pub events: Vec<TraceEvent>,
}

/// Resolves the application bundle manifest path.
///
/// Order: `TRAVERSE_STARTER_MANIFEST` → walk from `start`/`cwd` for
/// `manifests/traverse-starter/app.manifest.json`.
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
            .join("traverse-starter")
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
            let message = parsed
                .error_message
                .or_else(|| {
                    parsed
                        .raw
                        .get("data")
                        .and_then(|d| d.get("error"))
                        .and_then(|e| e.get("message"))
                        .and_then(|m| m.as_str())
                        .map(str::to_string)
                })
                .unwrap_or_else(|| "execution failed".to_string());
            return Err(HostError::Execution(message));
        }
        if parsed.event_type == "capability_result" {
            let output = parsed
                .output
                .unwrap_or_else(TraverseStarterOutput::empty);
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

/// Production embedded host backed by [`BundleEmbedder`].
pub struct EmbeddedRuntime {
    embedder: BundleEmbedder,
    events: Arc<Mutex<Vec<Value>>>,
    workspace_id: String,
    workflow_id: String,
}

impl EmbeddedRuntime {
    /// Initializes from an application bundle manifest (spec 044).
    ///
    /// Uses [`SecurityPosture::Development`] so locally built unsigned WASM
    /// artifacts from the linked Traverse examples can load during Phase 3
    /// cutover. Production posture can be selected once signed digests ship.
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

    /// Convenience: resolve manifest then init.
    pub fn init_default() -> Result<Self, HostError> {
        let path = resolve_manifest_path(None).ok_or_else(|| {
            HostError::Init(format!(
                "could not find manifests/traverse-starter/app.manifest.json (set {MANIFEST_ENV})"
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

    /// Submits `{ note }` to `traverse-starter.pipeline` and returns final output.
    pub fn submit_note(&mut self, note: &str) -> Result<HostRunResult, HostError> {
        collect_submit(
            &mut self.embedder,
            &self.events,
            &self.workflow_id,
            &json!({ "note": note }),
        )
    }

    pub fn shutdown(&mut self) {
        let _ = self.embedder.shutdown();
    }
}

/// Test-double host for unit/integration tests (spec 068 FR-006).
pub struct TestEmbeddedRuntime {
    embedder: EmbedderTestDouble,
    events: Arc<Mutex<Vec<Value>>>,
    workspace_id: String,
    workflow_id: String,
}

impl TestEmbeddedRuntime {
    #[must_use]
    pub fn new(output: TraverseStarterOutput) -> Self {
        let mut embedder = EmbedderTestDouble::new(
            crate::DEFAULT_WORKSPACE,
            crate::DEFAULT_APP_ID,
            "1.1.0",
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
    pub fn with_error(code: &str, message: &str) -> Self {
        let mut embedder = EmbedderTestDouble::new(
            crate::DEFAULT_WORKSPACE,
            crate::DEFAULT_APP_ID,
            "1.1.0",
            std::env::consts::OS,
        )
        .with_target_error(DEFAULT_WORKFLOW_ID, code, message);
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

    pub fn submit_note(&mut self, note: &str) -> Result<HostRunResult, HostError> {
        collect_submit(
            &mut self.embedder,
            &self.events,
            &self.workflow_id,
            &json!({ "note": note }),
        )
    }
}
