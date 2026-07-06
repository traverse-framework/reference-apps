package com.traverseframework.starter

sealed interface ExecutionPhase {
    data object Idle : ExecutionPhase
    data object Loading : ExecutionPhase
    data class Polling(val executionId: String) : ExecutionPhase
    data class Succeeded(val output: TraverseStarterOutput, val trace: List<TraceEvent>) : ExecutionPhase
    data class Failed(val error: String) : ExecutionPhase
}

enum class RuntimeStatus {
    Checking,
    Online,
    Offline,
}

data class ExecutionUiState(
    val phase: ExecutionPhase = ExecutionPhase.Idle,
    val note: String = "",
    val runtimeStatus: RuntimeStatus = RuntimeStatus.Checking,
    val baseUrl: String = AppConstants.DEFAULT_BASE_URL,
    val workspace: String = AppConstants.DEFAULT_WORKSPACE,
    val showTrace: Boolean = false,
) {
    val isRunning: Boolean
        get() = phase is ExecutionPhase.Loading || phase is ExecutionPhase.Polling

    val canSubmit: Boolean
        get() = runtimeStatus == RuntimeStatus.Online &&
            note.trim().isNotEmpty() &&
            !isRunning
}
