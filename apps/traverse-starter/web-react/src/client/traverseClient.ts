export interface TraceEvent {
  event_type: string
  timestamp: string
  data?: unknown
}

export interface CommandAccepted {
  api_version: string
  status: 'accepted'
  workspace_id: string
  app_id: string
  session_id: string
  command: string
  state: string
  execution_id?: string | null
  links: {
    events?: string
    sessions?: string
  }
}

export interface TraverseClient {
  sendCommand(
    workspaceId: string,
    appId: string,
    command: string,
    payload?: unknown,
    sessionId?: string,
  ): Promise<CommandAccepted>
  appEventsUrl(workspaceId: string, appId: string): string
  fetchTrace(workspaceId: string, executionId: string): Promise<TraceEvent[]>
}

export function createTraverseClient(baseUrl: string): TraverseClient {
  return {
    async sendCommand(workspaceId, appId, command, payload = {}, sessionId) {
      const body: Record<string, unknown> = { command, payload }
      if (sessionId) body.session_id = sessionId

      const res = await fetch(
        `${baseUrl}/v1/workspaces/${workspaceId}/apps/${appId}/commands`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        },
      )
      if (!res.ok) throw new Error(`sendCommand failed: ${res.status}`)
      return (await res.json()) as CommandAccepted
    },

    appEventsUrl(workspaceId, appId) {
      return `${baseUrl}/v1/workspaces/${workspaceId}/apps/${appId}/events`
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
