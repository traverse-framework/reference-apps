package com.traverseframework.starter

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ExecutionUiStateTest {
    @Test
    fun canSubmitRequiresOnlineNoteAndIdle() {
        val ready = ExecutionUiState(
            note = "hello",
            runtimeStatus = RuntimeStatus.Online,
            phase = ExecutionPhase.Idle,
        )
        assertTrue(ready.canSubmit)

        val offline = ready.copy(runtimeStatus = RuntimeStatus.Offline)
        assertFalse(offline.canSubmit)
    }
}
