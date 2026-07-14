use crate::client::{TraceEvent, TraverseStarterOutput};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionPhase {
    Idle,
    Loading,
    Succeeded {
        output: TraverseStarterOutput,
        trace: Vec<TraceEvent>,
    },
    Failed { error: String },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RuntimeStatus {
    Starting,
    Ready,
    Unavailable,
}

#[derive(Debug, Clone)]
pub struct ExecutionState {
    pub phase: ExecutionPhase,
    pub note: String,
    pub runtime_status: RuntimeStatus,
    pub show_trace: bool,
}

impl Default for ExecutionState {
    fn default() -> Self {
        Self {
            phase: ExecutionPhase::Idle,
            note: String::new(),
            runtime_status: RuntimeStatus::Starting,
            show_trace: false,
        }
    }
}

impl ExecutionState {
    pub fn is_running(&self) -> bool {
        matches!(self.phase, ExecutionPhase::Loading)
    }

    pub fn can_submit(&self, runtime_ready: bool) -> bool {
        runtime_ready && !self.note.trim().is_empty() && !self.is_running()
    }

    pub fn reset(&mut self) {
        self.phase = ExecutionPhase::Idle;
        self.show_trace = false;
    }
}
