package com.traverseframework.starter

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

class TraverseClient(
    engine: HttpClientEngine = CIO.create(),
) {
    private val json = Json { ignoreUnknownKeys = true }

    private val http = HttpClient(engine) {
        install(ContentNegotiation) {
            json(json)
        }
    }

    suspend fun checkHealth(baseUrl: String): Boolean {
        val response = http.get("$baseUrl/healthz")
        return response.status.isSuccess()
    }

    suspend fun execute(
        baseUrl: String,
        workspaceId: String,
        capability: String,
        input: Map<String, String>,
    ): String {
        val response = http.post("$baseUrl/v1/workspaces/$workspaceId/execute") {
            contentType(ContentType.Application.Json)
            setBody(ExecuteRequest(capability, input))
        }
        ensureSuccess(response)
        return response.body<ExecuteResponse>().execution_id
    }

    suspend fun pollExecution(
        baseUrl: String,
        workspaceId: String,
        executionId: String,
    ): ExecutionPollResult {
        val response = http.get("$baseUrl/v1/workspaces/$workspaceId/executions/$executionId")
        ensureSuccess(response)
        val body = response.body<ExecutionPollResponse>()
        return ExecutionPollResult(
            executionId = executionId,
            status = body.status,
            output = body.output,
            error = body.error,
        )
    }

    suspend fun fetchTrace(
        baseUrl: String,
        workspaceId: String,
        executionId: String,
    ): List<TraceEvent> {
        val response = http.get("$baseUrl/v1/workspaces/$workspaceId/traces/$executionId")
        ensureSuccess(response)
        return response.body()
    }

    private fun ensureSuccess(response: HttpResponse) {
        if (!response.status.isSuccess()) {
            throw TraverseClientException("HTTP ${response.status.value}")
        }
    }
}

@Serializable
private data class ExecuteRequest(
    val capability: String,
    val input: Map<String, String>,
)

class TraverseClientException(message: String) : Exception(message)
