//! Shared Traverse runtime client for loop Rust shells.
//! Platform-neutral: no GTK or terminal UI imports.
//!
//! Production path is the embedded host (`host` module).

mod client;
mod host;
mod presentation;
mod state;

pub use client::{ActionItem, Decision, LoopOutput, TraceEvent};
pub use host::{
    resolve_manifest_path, EmbeddedRuntime, HostError, HostRunResult, TestEmbeddedRuntime,
    DEFAULT_WORKFLOW_ID, MANIFEST_ENV, RUNTIME_MODE_EMBEDDED,
};
pub use presentation::{
    active_capability_id, map_capability_progress, map_presentation_state, CapabilityPhase,
    CapabilityProgressStep, EmbedderEventLike, PresentationSnapshot, PresentationState,
};
pub use state::{AppState, StateEvent};

pub const DEFAULT_APP_ID: &str = "loop";
pub const DEFAULT_WORKSPACE: &str = "local-default";
