pub mod client;
pub mod execution_state;
pub mod settings;
pub mod ui;

pub use traverse_core_rs::{
    DEFAULT_APP_ID, DEFAULT_WORKFLOW_ID, DEFAULT_WORKSPACE, RUNTIME_MODE_EMBEDDED,
};
pub const NOTE_MAX_LENGTH: usize = 2000;
