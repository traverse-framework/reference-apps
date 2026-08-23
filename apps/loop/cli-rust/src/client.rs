//! Re-exports the shared loop-core-rs embedded host for the CLI shell.
pub use loop_core_rs::{
    LoopOutput, EmbeddedRuntime, HostError, HostRunResult, TraceEvent, DEFAULT_APP_ID,
    DEFAULT_WORKFLOW_ID, DEFAULT_WORKSPACE, RUNTIME_MODE_EMBEDDED,
};
