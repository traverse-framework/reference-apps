//! Shared Traverse runtime client for traverse-starter Rust shells.
//! Platform-neutral: no GTK or terminal UI imports.

mod client;
mod discovery;
mod sse;
mod state;

pub use client::{
    CommandAccepted, ProcessOutput, SummarizeOutput, TraceEvent, TraverseClient,
    TraverseClientError, TraverseStarterOutput, ValidateOutput,
};
pub use discovery::{ServerDiscovery, ServerInfo};
pub use sse::subscribe_events;
pub use state::{AppState, StateEvent};

pub const DEFAULT_APP_ID: &str = "traverse-starter";
pub const DEFAULT_BASE_URL: &str = "http://127.0.0.1:8787";
pub const DEFAULT_WORKSPACE: &str = "local-default";
