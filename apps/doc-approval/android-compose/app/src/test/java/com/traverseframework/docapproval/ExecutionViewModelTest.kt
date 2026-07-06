package com.traverseframework.docapproval

import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
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
    fun canSubmitWhenOnlineWithDocument() = runTest(testDispatcher) {
        val engine = MockEngine { respond("", status = HttpStatusCode.OK) }
        val vm = ExecutionViewModel(TraverseClient(engine), FakeRuntimeSettings())
        advanceUntilIdle()
        vm.updateDocument("contract text")
        assertTrue(vm.uiState.value.canSubmit)
    }

    @Test
    fun resetReturnsToIdle() = runTest(testDispatcher) {
        val engine = MockEngine { respond("", status = HttpStatusCode.OK) }
        val vm = ExecutionViewModel(TraverseClient(engine), FakeRuntimeSettings())
        vm.reset()
        assertEquals(ExecutionPhase.Idle, vm.uiState.value.phase)
    }
}

private class FakeRuntimeSettings(
    base: String = AppConstants.DEFAULT_BASE_URL,
    workspace: String = AppConstants.DEFAULT_WORKSPACE,
) : RuntimeSettings {
    private val _base = MutableStateFlow(base)
    override val baseUrl = _base
    private val _workspace = MutableStateFlow(workspace)
    override val workspace = _workspace

    override suspend fun setBaseUrl(url: String) {
        _base.value = url
    }

    override suspend fun setWorkspace(workspace: String) {
        _workspace.value = workspace
    }
}
