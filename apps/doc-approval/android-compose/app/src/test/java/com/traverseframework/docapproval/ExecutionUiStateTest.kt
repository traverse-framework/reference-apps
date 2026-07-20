package com.traverseframework.docapproval

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExecutionUiStateTest {
    @Test
    fun canSubmitRequiresReadyAndDocument() {
        val idle = ExecutionUiState(runtimeStatus = RuntimeStatus.Ready, document = "contract text")
        assertTrue(idle.canSubmit)

        val unavailable = ExecutionUiState(runtimeStatus = RuntimeStatus.Unavailable, document = "contract text")
        assertEquals(false, unavailable.canSubmit)

        val empty = ExecutionUiState(runtimeStatus = RuntimeStatus.Ready, document = "  ")
        assertEquals(false, empty.canSubmit)
    }
}
