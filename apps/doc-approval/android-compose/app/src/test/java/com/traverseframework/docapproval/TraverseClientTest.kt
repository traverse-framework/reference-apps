package com.traverseframework.docapproval

import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TraverseClientTest {
    @Test
    fun checkHealthReturnsTrueOn200() = runBlocking {
        val engine = MockEngine {
            respond("", status = HttpStatusCode.OK)
        }
        val client = TraverseClient(engine)
        assertTrue(client.checkHealth("http://10.0.2.2:8787"))
    }

    @Test
    fun executeReturnsExecutionId() = runBlocking {
        val engine = MockEngine {
            respond(
                content = """{"execution_id":"exec_abc"}""",
                status = HttpStatusCode.OK,
                headers = headersOf(HttpHeaders.ContentType, "application/json"),
            )
        }
        val client = TraverseClient(engine)
        val id = client.execute(
            baseUrl = "http://10.0.2.2:8787",
            workspaceId = "local-default",
            capability = AppConstants.CAPABILITY_ID,
            input = mapOf("document" to "contract"),
        )
        assertEquals("exec_abc", id)
    }

    @Test
    fun pollExecutionParsesOutput() = runBlocking {
        val engine = MockEngine {
            respond(
                content = """
                {"status":"succeeded","output":{"docType":"invoice","parties":["A","B"],"amounts":["$100"],"confidence":0.9,"recommendation":"approve"}}
                """.trimIndent(),
                status = HttpStatusCode.OK,
                headers = headersOf(HttpHeaders.ContentType, "application/json"),
            )
        }
        val client = TraverseClient(engine)
        val result = client.pollExecution("http://10.0.2.2:8787", "local-default", "exec_abc")
        assertEquals("succeeded", result.status)
        assertEquals("invoice", result.output?.docType)
    }
}
