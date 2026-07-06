use crate::client::{TraceEvent, TraverseStarterOutput};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionPhase {
    Idle,
    Loading,
    Polling { execution_id: String },
    Succeeded {
        output: TraverseStarterOutput,
        trace: Vec<TraceEvent>,
    },
    Failed { error: String },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RuntimeStatus {
    Checking,
    Online,
    Offline,
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
            runtime_status: RuntimeStatus::Checking,
            show_trace: false,
        }
    }
}

impl ExecutionState {
    pub fn is_running(&self) -> bool {
        matches!(
            self.phase,
            ExecutionPhase::Loading | ExecutionPhase::Polling { .. }
        )
    }

    pub fn can_submit(&self, runtime_online: bool) -> bool {
        runtime_online && !self.note.trim().is_empty() && !self.is_running()
    }

    pub fn reset(&mut self) {
        self.phase = ExecutionPhase::Idle;
        self.show_trace = false;
    }
}
