//! Shared Traverse runtime client for traverse-starter Rust shells.
//! Platform-neutral: no GTK or terminal UI imports.
//!
//! Production path is the embedded host (`host` module). HTTP sidecar clients
//! were removed — see `docs/traverse-runtime.md` (appendix / Trace Explorer /
//! meeting-notes interim carve-outs only).

mod client;
mod host;
mod state;

pub use client::{
    ProcessOutput, SummarizeOutput, TraceEvent, TraverseStarterOutput, ValidateOutput,
};
pub use host::{
    resolve_manifest_path, EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
    DEFAULT_WORKFLOW_ID, MANIFEST_ENV, RUNTIME_MODE_EMBEDDED,
};
pub use state::{AppState, StateEvent};

pub const DEFAULT_APP_ID: &str = "traverse-starter";
pub const DEFAULT_WORKSPACE: &str = "local-default";
