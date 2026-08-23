package com.traverseframework.loop

import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PresentationMapperTest {
    @Test
    fun emptyStreamIsIdle() {
        val snap = PresentationMapper.mapPresentationState(emptyList())
        assertEquals(PresentationState.Idle, snap.state)
        assertNull(snap.errorMessage)
    }

    @Test
    fun happyPathLoads() {
        val events = listOf(
            EmbedderEventLike(
                eventType = "capability_invoked",
                sequence = 1,
                data = buildJsonObject { put("capability_id", "fixture.process") },
            ),
            EmbedderEventLike(
                eventType = "capability_result",
                sequence = 2,
                data = buildJsonObject {
                    put("capability_id", "fixture.process")
                    put("output", buildJsonObject { put("ok", true) })
                },
            ),
        )
        assertEquals(PresentationState.Loaded, PresentationMapper.mapPresentationState(events).state)
        assertNull(PresentationMapper.activeCapabilityId(events))
        assertEquals(
            listOf("fixture.process", "fixture.process"),
            PresentationMapper.mapCapabilityProgress(events).map { it.capabilityId },
        )
    }

    @Test
    fun blockedWaitingForHuman() {
        val events = listOf(
            EmbedderEventLike(
                eventType = "capability_invoked",
                sequence = 1,
                data = buildJsonObject { put("capability_id", "fixture.approve") },
            ),
            EmbedderEventLike(
                eventType = "state_changed",
                sequence = 2,
                data = buildJsonObject { put("state", "waiting_for_human") },
            ),
        )
        assertEquals(PresentationState.Blocked, PresentationMapper.mapPresentationState(events).state)
        assertEquals("fixture.approve", PresentationMapper.activeCapabilityId(events))
    }
}
