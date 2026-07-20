package com.traverseframework.starter

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExecutionUiStateTest {
    @Test
    fun canSubmitRequiresReadyAndNote() {
        val idle = ExecutionUiState(runtimeStatus = RuntimeStatus.Ready, note = "x")
        assertTrue(idle.canSubmit)

        val unavailable = ExecutionUiState(runtimeStatus = RuntimeStatus.Unavailable, note = "x")
        assertEquals(false, unavailable.canSubmit)

        val empty = ExecutionUiState(runtimeStatus = RuntimeStatus.Ready, note = "  ")
        assertEquals(false, empty.canSubmit)
    }
}
