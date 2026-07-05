export interface TraceEvent {
  event_type: string
  timestamp: string
  data?: unknown
}

export function createTraceClient(baseUrl: string) {
  return {
    async fetchTrace(workspaceId: string, executionId: string): Promise<TraceEvent[]> {
      const res = await fetch(
        `${baseUrl}/v1/workspaces/${workspaceId}/traces/${executionId}`,
      )
      if (!res.ok) throw new Error(`trace fetch failed: ${res.status}`)
      const body = await res.json()
      return Array.isArray(body) ? body as TraceEvent[] : (body.events as TraceEvent[] ?? [])
    },
  }
}

export function eventPreview(data: unknown): string {
  if (data === undefined || data === null) return '—'
  const text = typeof data === 'string' ? data : JSON.stringify(data)
  return text.length > 60 ? `${text.slice(0, 57)}…` : text
}
