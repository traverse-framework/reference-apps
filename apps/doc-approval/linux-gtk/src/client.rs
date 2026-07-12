//! Re-exports the shared doc-approval-core-rs client for the GTK shell.
pub use doc_approval_core_rs::{
    DocApprovalClient as TraverseClient, DocApprovalClientError as TraverseClientError,
    DocApprovalOutput, TraceEvent, DEFAULT_APP_ID,
};
