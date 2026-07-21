//! Re-exports the shared meeting-notes-core-rs embedded host for the GTK shell.
pub use meeting_notes_core_rs::{
    MeetingNotesOutput, EmbeddedRuntime, HostError, HostRunResult, TraceEvent, DEFAULT_APP_ID,
    DEFAULT_WORKFLOW_ID, DEFAULT_WORKSPACE, RUNTIME_MODE_EMBEDDED,
};
