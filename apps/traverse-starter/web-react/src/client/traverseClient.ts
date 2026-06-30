export type ExecutionStatus = 'pending' | 'running' | 'succeeded' | 'failed'

export interface ExecutionResult {
  execution_id?: string
  status: ExecutionStatus
  output?: unknown
  error?: string
}

export interface TraceEvent {
  event_type: string
  timestamp: string
  data?: unknown
}

export interface ExecuteResponse {
  executionId?: string
  result?: ExecutionResult
}

export interface TraverseClient {
  execute(workspaceId: string, capabilityId: string, input: unknown): Promise<ExecuteResponse>
  pollExecution(workspaceId: string, executionId: string): Promise<ExecutionResult>
  fetchTrace(workspaceId: string, executionId: string): Promise<TraceEvent[]>
}

export function createTraverseClient(baseUrl: string): TraverseClient {
  return {
    async execute(workspaceId, capabilityId, input) {
      const res = await fetch(
        `${baseUrl}/v1/workspaces/${workspaceId}/execute`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ capability_id: capabilityId, input }),
        },
      )
      if (!res.ok) throw new Error(`execute failed: ${res.status}`)
      const data = (await res.json()) as ExecutionResult & { execution_id?: string }
      if (data.status === 'succeeded' && !data.execution_id) {
        return { result: data }
      }
      if (!data.execution_id) {
        throw new Error('execute response missing execution_id')
      }
      return { executionId: data.execution_id }
    },

    async pollExecution(workspaceId, executionId) {
      const res = await fetch(
        `${baseUrl}/v1/workspaces/${workspaceId}/executions/${executionId}`,
      )
      if (!res.ok) throw new Error(`poll failed: ${res.status}`)
      return (await res.json()) as ExecutionResult
    },

    async fetchTrace(workspaceId, executionId) {
      const res = await fetch(
        `${baseUrl}/v1/workspaces/${workspaceId}/traces/${executionId}`,
      )
      if (!res.ok) throw new Error(`trace fetch failed: ${res.status}`)
      const data = await res.json()
      return Array.isArray(data) ? (data as TraceEvent[]) : (data.events as TraceEvent[] ?? [])
    },
  }
}
