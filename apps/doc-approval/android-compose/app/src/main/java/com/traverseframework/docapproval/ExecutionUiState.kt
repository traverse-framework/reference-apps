package com.traverseframework.docapproval

sealed interface ExecutionPhase {
    data object Idle : ExecutionPhase
    data object Loading : ExecutionPhase
    data class Succeeded(val output: DocApprovalOutput, val trace: List<TraceEvent>) : ExecutionPhase
    data class Failed(val error: String) : ExecutionPhase
}

enum class RuntimeStatus {
    Starting,
    Ready,
    Unavailable,
}

data class ExecutionUiState(
    val phase: ExecutionPhase = ExecutionPhase.Idle,
    val document: String = "",
    val runtimeStatus: RuntimeStatus = RuntimeStatus.Starting,
    val runtimeMode: String = AppConstants.RUNTIME_MODE_EMBEDDED,
    val workspace: String = AppConstants.DEFAULT_WORKSPACE,
    val showTrace: Boolean = false,
) {
    val isRunning: Boolean
        get() = phase is ExecutionPhase.Loading

    val canSubmit: Boolean
        get() = runtimeStatus == RuntimeStatus.Ready &&
            document.trim().isNotEmpty() &&
            !isRunning
}
