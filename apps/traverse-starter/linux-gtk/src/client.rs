//! Re-exports the shared traverse-core-rs embedded host for the GTK shell.
pub use traverse_core_rs::{
    EmbeddedRuntime, HostError, HostRunResult, TraceEvent, TraverseStarterOutput, DEFAULT_APP_ID,
    DEFAULT_WORKFLOW_ID, DEFAULT_WORKSPACE, RUNTIME_MODE_EMBEDDED,
};
