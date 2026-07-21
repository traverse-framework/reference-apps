//! Shared Traverse embedded-runtime types for doc-approval Rust shells.
//! Platform-neutral: no GTK or terminal UI imports.
//!
//! Production path is the embedded host (`host` module). HTTP sidecar clients
//! were removed (`remove-sidecar-paths`); see `docs/traverse-runtime.md` appendix.

mod client;
mod host;
mod state;

pub use client::{
    AnalysisOutput, DocApprovalOutput, RecommendationOutput, TraceEvent,
};
pub use host::{
    resolve_manifest_path, EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
    DEFAULT_WORKFLOW_ID, MANIFEST_ENV, RUNTIME_MODE_EMBEDDED,
};
pub use state::{AppState, StateEvent};

pub const DEFAULT_APP_ID: &str = "doc-approval";
pub const DEFAULT_WORKSPACE: &str = "local-default";
