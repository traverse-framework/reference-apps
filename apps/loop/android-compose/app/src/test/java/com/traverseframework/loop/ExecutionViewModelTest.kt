package com.traverseframework.loop

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
    fun canSubmitWhenReadyWithTranscript() = runTest(testDispatcher) {
        val host = InMemoryLoopHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings(), testDispatcher)
        advanceUntilIdle()
        vm.updateTranscript("Team agreed on launch tasks")
        assertTrue(vm.uiState.value.canSubmit)
        assertEquals(RuntimeStatus.Ready, vm.uiState.value.runtimeStatus)
        assertEquals(AppConstants.RUNTIME_MODE_EMBEDDED, vm.uiState.value.runtimeMode)
    }

    @Test
    fun submitRendersRuntimeOwnedFields() = runTest(testDispatcher) {
        val host = InMemoryLoopHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings(), testDispatcher)
        advanceUntilIdle()
        vm.updateTranscript("Launch review transcript")
        vm.submit()
        advanceUntilIdle()
        val phase = vm.uiState.value.phase
        assertTrue(phase is ExecutionPhase.Succeeded)
        val output = (phase as ExecutionPhase.Succeeded).output
        assertEquals("Prepare launch checklist", output.action_items.first().task)
        assertEquals("Ship the beta on Friday", output.decisions.first().text)
        assertEquals("Team aligned on beta launch readiness.", output.summary)
    }

    @Test
    fun resetReturnsToIdle() = runTest(testDispatcher) {
        val host = InMemoryLoopHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings(), testDispatcher)
        vm.reset()
        assertEquals(ExecutionPhase.Idle, vm.uiState.value.phase)
    }
}

private fun sampleOutput() = LoopOutput(
    action_items = listOf(
        ActionItem(task = "Prepare launch checklist", owner = "Avery", due = "Friday"),
    ),
    decisions = listOf(
        Decision(text = "Ship the beta on Friday", made_by = "Morgan"),
    ),
    follow_ups = listOf("Confirm support rotation"),
    summary = "Team aligned on beta launch readiness.",
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
