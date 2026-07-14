//! Re-exports the shared doc-approval-core-rs embedded host for the GTK shell.
pub use doc_approval_core_rs::{
    DocApprovalOutput, EmbeddedRuntime, HostError, HostRunResult, TraceEvent, DEFAULT_APP_ID,
    DEFAULT_WORKFLOW_ID, DEFAULT_WORKSPACE, RUNTIME_MODE_EMBEDDED,
};
