package com.traverseframework.meetingnotes

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExecutionUiStateTest {
    @Test
    fun canSubmitRequiresReadyAndTranscript() {
        val idle = ExecutionUiState(runtimeStatus = RuntimeStatus.Ready, transcript = "meeting transcript")
        assertTrue(idle.canSubmit)

        val unavailable = ExecutionUiState(runtimeStatus = RuntimeStatus.Unavailable, transcript = "meeting transcript")
        assertEquals(false, unavailable.canSubmit)

        val empty = ExecutionUiState(runtimeStatus = RuntimeStatus.Ready, transcript = "  ")
        assertEquals(false, empty.canSubmit)
    }
}
