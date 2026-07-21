use crate::client::{MeetingNotesOutput, TraceEvent};

#[derive(Debug, Clone, PartialEq)]
pub enum ExecutionPhase {
    Idle,
    Loading,
    Succeeded {
        output: MeetingNotesOutput,
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
    pub transcript: String,
    pub runtime_status: RuntimeStatus,
    pub show_trace: bool,
}

impl Default for ExecutionState {
    fn default() -> Self {
        Self {
            phase: ExecutionPhase::Idle,
            transcript: String::new(),
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
        runtime_ready && !self.transcript.trim().is_empty() && !self.is_running()
    }

    pub fn reset(&mut self) {
        self.phase = ExecutionPhase::Idle;
        self.transcript.clear();
        self.show_trace = false;
    }
}
