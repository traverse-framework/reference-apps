package com.traverseframework.docapproval

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ExecutionUiStateTest {
    @Test
    fun canSubmitRequiresOnlineDocumentAndIdle() {
        val ready = ExecutionUiState(
            document = "contract",
            runtimeStatus = RuntimeStatus.Online,
            phase = ExecutionPhase.Idle,
        )
        assertTrue(ready.canSubmit)

        val offline = ready.copy(runtimeStatus = RuntimeStatus.Offline)
        assertFalse(offline.canSubmit)
    }
}
