//! Shared Traverse runtime client for doc-approval Rust shells.
//! Platform-neutral: no GTK or terminal UI imports.

mod client;
mod discovery;
mod sessions;
mod sse;
mod state;

pub use client::{
    CommandAccepted, DocApprovalClient, DocApprovalClientError, DocApprovalOutput, TraceEvent,
};
pub use discovery::{ServerDiscovery, ServerInfo};
pub use sessions::{list_sessions, parse_sessions, SessionSummary};
pub use sse::subscribe_events;
pub use state::{AppState, StateEvent};

pub const DEFAULT_APP_ID: &str = "doc-approval";
pub const DEFAULT_BASE_URL: &str = "http://127.0.0.1:8787";
pub const DEFAULT_WORKSPACE: &str = "local-default";
