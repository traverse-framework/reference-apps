package com.traverseframework.docapproval

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class ExecutionViewModel(
    private val client: TraverseClient,
    private val settings: RuntimeSettings,
) : ViewModel() {
    private val _uiState = MutableStateFlow(ExecutionUiState())
    val uiState: StateFlow<ExecutionUiState> = _uiState.asStateFlow()

    private var pollJob: Job? = null
    private var healthJob: Job? = null

    init {
        viewModelScope.launch {
            settings.baseUrl.collect { url ->
                _uiState.update { it.copy(baseUrl = url) }
                refreshHealth()
            }
        }
        viewModelScope.launch {
            settings.workspace.collect { workspace ->
                _uiState.update { it.copy(workspace = workspace) }
            }
        }
        startHealthChecks()
    }

    fun updateDocument(document: String) {
        _uiState.update { it.copy(document = document) }
    }

    fun toggleTrace(show: Boolean) {
        _uiState.update { it.copy(showTrace = show) }
    }

    fun submit() {
        val state = _uiState.value
        if (!state.canSubmit) return
        pollJob?.cancel()
        _uiState.update { it.copy(phase = ExecutionPhase.Loading) }
        val document = state.document.trim()
        pollJob = viewModelScope.launch {
            try {
                val executionId = client.execute(
                    baseUrl = state.baseUrl.trimEnd('/'),
                    workspaceId = state.workspace,
                    capability = AppConstants.CAPABILITY_ID,
                    input = mapOf("document" to document),
                )
                _uiState.update { it.copy(phase = ExecutionPhase.Polling(executionId)) }
                pollUntilTerminal(state.baseUrl.trimEnd('/'), state.workspace, executionId)
            } catch (e: Exception) {
                _uiState.update { it.copy(phase = ExecutionPhase.Failed(e.message ?: "unknown error")) }
            }
        }
    }

    fun reset() {
        pollJob?.cancel()
        pollJob = null
        _uiState.update { it.copy(phase = ExecutionPhase.Idle, document = "", showTrace = false) }
    }

    private fun startHealthChecks() {
        healthJob?.cancel()
        healthJob = viewModelScope.launch {
            while (isActive) {
                refreshHealth()
                delay(5_000)
            }
        }
    }

    private suspend fun refreshHealth() {
        val baseUrl = _uiState.value.baseUrl.trimEnd('/')
        _uiState.update { it.copy(runtimeStatus = RuntimeStatus.Checking) }
        _uiState.update {
            it.copy(
                runtimeStatus = try {
                    if (client.checkHealth(baseUrl)) RuntimeStatus.Online else RuntimeStatus.Offline
                } catch (_: Exception) {
                    RuntimeStatus.Offline
                },
            )
        }
    }

    private suspend fun pollUntilTerminal(baseUrl: String, workspaceId: String, executionId: String) {
        while (true) {
            val result = client.pollExecution(baseUrl, workspaceId, executionId)
            when (result.status) {
                "succeeded" -> {
                    val trace = try {
                        client.fetchTrace(baseUrl, workspaceId, executionId)
                    } catch (_: Exception) {
                        emptyList()
                    }
                    val output = result.output ?: DocApprovalOutput.EMPTY
                    _uiState.update { it.copy(phase = ExecutionPhase.Succeeded(output, trace)) }
                    return
                }
                "failed" -> {
                    _uiState.update {
                        it.copy(phase = ExecutionPhase.Failed(result.error ?: "execution failed"))
                    }
                    return
                }
                else -> delay(1_000)
            }
        }
    }
}
