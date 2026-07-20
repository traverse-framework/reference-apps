package com.traverseframework.docapproval

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ExecutionViewModelTest {
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun canSubmitWhenReadyWithDocument() = runTest(testDispatcher) {
        val host = InMemoryDocApprovalHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings())
        advanceUntilIdle()
        vm.updateDocument("invoice text")
        assertTrue(vm.uiState.value.canSubmit)
        assertEquals(RuntimeStatus.Ready, vm.uiState.value.runtimeStatus)
        assertEquals(AppConstants.RUNTIME_MODE_EMBEDDED, vm.uiState.value.runtimeMode)
    }

    @Test
    fun submitRendersRuntimeOwnedFields() = runTest(testDispatcher) {
        val host = InMemoryDocApprovalHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings())
        advanceUntilIdle()
        vm.updateDocument("Invoice for services rendered")
        vm.submit()
        advanceUntilIdle()
        val phase = vm.uiState.value.phase
        assertTrue(phase is ExecutionPhase.Succeeded)
        val output = (phase as ExecutionPhase.Succeeded).output
        assertEquals("invoice", output.analysis.docType)
        assertEquals("approve", output.recommendation.recommendation)
    }

    @Test
    fun resetReturnsToIdle() = runTest(testDispatcher) {
        val host = InMemoryDocApprovalHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings())
        vm.reset()
        assertEquals(ExecutionPhase.Idle, vm.uiState.value.phase)
    }
}

private fun sampleOutput() = DocApprovalOutput(
    analysis = AnalysisOutput(
        docType = "invoice",
        parties = listOf("Acme Corp", "Client Inc"),
        amounts = listOf("$1000"),
        confidence = "0.95",
        recommendation = "approve",
    ),
    recommendation = RecommendationOutput(
        recommendation = "approve",
        rationale = "Matches standard invoice policy",
        confidence = "high",
    ),
)

private class FakeRuntimeSettings(
    workspace: String = AppConstants.DEFAULT_WORKSPACE,
) : RuntimeSettings {
    private val _workspace = MutableStateFlow(workspace)
    override val workspace = _workspace

    override suspend fun setWorkspace(workspace: String) {
        _workspace.value = workspace
    }
}
