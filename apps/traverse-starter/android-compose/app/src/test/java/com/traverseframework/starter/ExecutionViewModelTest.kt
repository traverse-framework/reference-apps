package com.traverseframework.starter

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
    fun canSubmitWhenReadyWithNote() = runTest(testDispatcher) {
        val host = InMemoryStarterHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings())
        advanceUntilIdle()
        vm.updateNote("hello")
        assertTrue(vm.uiState.value.canSubmit)
        assertEquals(RuntimeStatus.Ready, vm.uiState.value.runtimeStatus)
        assertEquals(AppConstants.RUNTIME_MODE_EMBEDDED, vm.uiState.value.runtimeMode)
    }

    @Test
    fun submitRendersRuntimeOwnedFields() = runTest(testDispatcher) {
        val host = InMemoryStarterHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings())
        advanceUntilIdle()
        vm.updateNote("Meeting with Alice")
        vm.submit()
        advanceUntilIdle()
        val phase = vm.uiState.value.phase
        assertTrue(phase is ExecutionPhase.Succeeded)
        val output = (phase as ExecutionPhase.Succeeded).output
        assertEquals("Alice Meeting", output.process.title)
        assertEquals("meeting", output.process.noteType)
    }

    @Test
    fun resetReturnsToIdle() = runTest(testDispatcher) {
        val host = InMemoryStarterHost.withScriptedOutput(sampleOutput())
        val vm = ExecutionViewModel(host, FakeRuntimeSettings())
        vm.reset()
        assertEquals(ExecutionPhase.Idle, vm.uiState.value.phase)
    }
}

private fun sampleOutput() = TraverseStarterOutput(
    validate = ValidateOutput(valid = true, issues = emptyList()),
    process = ProcessOutput(
        title = "Alice Meeting",
        tags = listOf("meeting"),
        noteType = "meeting",
        suggestedNextAction = "Schedule follow-up",
        status = "ready",
    ),
    summarize = SummarizeOutput(summary = "Met with Alice", wordCount = 3),
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
