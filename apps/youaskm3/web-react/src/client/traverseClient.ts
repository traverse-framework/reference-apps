export type ExecutionStatus = 'pending' | 'running' | 'succeeded' | 'failed'

export interface ExecutionResult {
  execution_id: string
  status: ExecutionStatus
  output?: unknown
  error?: string
}

export interface TraceEvent {
  event_type: string
  timestamp: string
  data?: unknown
}

export interface TraverseClient {
  execute(workspaceId: string, capability: string, input: unknown): Promise<string>
  pollExecution(workspaceId: string, executionId: string): Promise<ExecutionResult>
  fetchTrace(workspaceId: string, executionId: string): Promise<TraceEvent[]>
}

export function createTraverseClient(baseUrl: string): TraverseClient {
  return {
    async execute(workspaceId, capability, input) {
      const res = await fetch(
        `${baseUrl}/v1/workspaces/${workspaceId}/execute`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ capability, input }),
        },
      )
      if (!res.ok) throw new Error(`execute failed: ${res.status}`)
      const data = (await res.json()) as { execution_id: string }
      return data.execution_id
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
      return (await res.json()) as TraceEvent[]
    },
  }
}
