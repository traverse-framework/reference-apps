//! Shared Traverse runtime client for meeting-notes Rust shells.
//! Platform-neutral: no GTK or terminal UI imports.
//!
//! Production path is the embedded host (`host` module).

mod client;
mod host;
mod state;

pub use client::{ActionItem, Decision, MeetingNotesOutput, TraceEvent};
pub use host::{
    resolve_manifest_path, EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
    DEFAULT_WORKFLOW_ID, MANIFEST_ENV, RUNTIME_MODE_EMBEDDED,
};
pub use state::{AppState, StateEvent};

pub const DEFAULT_APP_ID: &str = "meeting-notes";
pub const DEFAULT_WORKSPACE: &str = "local-default";
