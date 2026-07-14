//! Shared Traverse runtime client for doc-approval Rust shells.
//! Platform-neutral: no GTK or terminal UI imports.
//!
//! Phase 3 production path is the embedded host (`host` module). HTTP sidecar
//! helpers remain for migration/debug until manifests (#112) land.

mod client;
mod discovery;
mod host;
mod sessions;
mod sse;
mod state;

pub use client::{
    CommandAccepted, DocApprovalClient, DocApprovalClientError, DocApprovalOutput, TraceEvent,
};
pub use discovery::{ServerDiscovery, ServerInfo};
pub use host::{
    resolve_manifest_path, EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
    DEFAULT_WORKFLOW_ID, MANIFEST_ENV, RUNTIME_MODE_EMBEDDED,
};
pub use sessions::{list_sessions, parse_sessions, SessionSummary};
pub use sse::subscribe_events;
pub use state::{AppState, StateEvent};

pub const DEFAULT_APP_ID: &str = "doc-approval";
pub const DEFAULT_BASE_URL: &str = "http://127.0.0.1:8787";
pub const DEFAULT_WORKSPACE: &str = "local-default";
