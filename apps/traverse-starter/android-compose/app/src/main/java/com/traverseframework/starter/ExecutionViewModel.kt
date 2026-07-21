package com.traverseframework.starter

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ExecutionViewModel(
    private val host: StarterHost,
    private val settings: RuntimeSettings,
    private val computeDispatcher: CoroutineDispatcher = Dispatchers.Default,
) : ViewModel() {
    private val _uiState = MutableStateFlow(
        ExecutionUiState(
            runtimeStatus = if (host.isReady) RuntimeStatus.Ready else RuntimeStatus.Unavailable,
            runtimeMode = host.runtimeMode,
            workspace = AppConstants.DEFAULT_WORKSPACE,
        ),
    )
    val uiState: StateFlow<ExecutionUiState> = _uiState.asStateFlow()

    private var submitJob: Job? = null

    init {
        viewModelScope.launch {
            settings.workspace.collect { workspace ->
                _uiState.update { it.copy(workspace = workspace) }
            }
        }
    }

    fun updateNote(note: String) {
        _uiState.update { it.copy(note = note.take(AppConstants.NOTE_MAX_LENGTH)) }
    }

    fun toggleTrace(show: Boolean) {
        _uiState.update { it.copy(showTrace = show) }
    }

    fun submit() {
        val state = _uiState.value
        if (!state.canSubmit) return
        submitJob?.cancel()
        _uiState.update { it.copy(phase = ExecutionPhase.Loading) }
        val note = state.note.trim()
        submitJob = viewModelScope.launch {
            val result = withContext(computeDispatcher) { host.submitNote(note) }
            if (result.error != null && result.output == null) {
                _uiState.update { it.copy(phase = ExecutionPhase.Failed(result.error)) }
            } else {
                _uiState.update {
                    it.copy(
                        phase = ExecutionPhase.Succeeded(
                            result.output ?: TraverseStarterOutput.EMPTY,
                            result.events,
                        ),
                    )
                }
            }
        }
    }

    fun reset() {
        submitJob?.cancel()
        submitJob = null
        _uiState.update { it.copy(phase = ExecutionPhase.Idle, showTrace = false) }
    }
}
