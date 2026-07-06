use crate::client::{DocApprovalOutput, TraceEvent};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionPhase {
    Idle,
    Loading,
    Polling { execution_id: String },
    Succeeded {
        output: DocApprovalOutput,
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
    pub document: String,
    pub runtime_status: RuntimeStatus,
    pub show_trace: bool,
}

impl Default for ExecutionState {
    fn default() -> Self {
        Self {
            phase: ExecutionPhase::Idle,
            document: String::new(),
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
        runtime_online && !self.document.trim().is_empty() && !self.is_running()
    }

    pub fn reset(&mut self) {
        self.phase = ExecutionPhase::Idle;
        self.document.clear();
        self.show_trace = false;
    }
}
