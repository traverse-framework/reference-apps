import { useEffect, useState } from 'react'
import type { TraverseClient } from '../client/traverseClient'

/** Runtime-owned app states for traverse-starter (spec 052). */
export type AppRuntimeState = 'idle' | 'processing' | 'results' | 'error' | string

export interface AppStateEventPayload {
  workspace_id?: string
  app_id?: string
  session_id?: string
  execution_id?: string
  state?: string
  previous_state?: string
  output?: unknown
  error?: { code?: string; message?: string } | string
  timestamp?: string
}

export interface AppStateView {
  state: AppRuntimeState
  sessionId: string | null
  executionId: string | null
  output: unknown | null
  error: string | null
  connected: boolean
}

const INITIAL: AppStateView = {
  state: 'idle',
  sessionId: null,
  executionId: null,
  output: null,
  error: null,
  connected: false,
}

function errorMessage(error: AppStateEventPayload['error']): string | null {
  if (error == null) return null
  if (typeof error === 'string') return error
  if (typeof error.message === 'string') return error.message
  return 'execution failed'
}

function applyEvent(prev: AppStateView, payload: AppStateEventPayload): AppStateView {
  const next: AppStateView = {
    ...prev,
    connected: true,
  }
  if (typeof payload.state === 'string' && payload.state.length > 0) {
    next.state = payload.state
  }
  if (typeof payload.session_id === 'string') {
    next.sessionId = payload.session_id
  }
  if (typeof payload.execution_id === 'string') {
    next.executionId = payload.execution_id
  }
  if (payload.output !== undefined) {
    next.output = payload.output
  }
  const err = errorMessage(payload.error)
  if (err != null) {
    next.error = err
  } else if (payload.state === 'results') {
    next.error = null
  }
  return next
}

function parsePayload(raw: string): AppStateEventPayload | null {
  try {
    const data = JSON.parse(raw) as unknown
    if (!data || typeof data !== 'object') return null
    return data as AppStateEventPayload
  } catch {
    return null
  }
}

/**
 * Subscribes to runtime app state via SSE. Maps event payloads to render state only —
 * no local transition or polling logic.
 */
export function useAppState(
  client: TraverseClient,
  workspaceId: string,
  appId = 'traverse-starter',
  EventSourceCtor: typeof EventSource = EventSource,
): AppStateView {
  const [view, setView] = useState<AppStateView>(INITIAL)

  useEffect(() => {
    const url = client.appEventsUrl(workspaceId, appId)
    const source = new EventSourceCtor(url)

    const onTypedEvent = (event: Event) => {
      const message = event as MessageEvent<string>
      const payload = parsePayload(message.data)
      if (!payload) return
      // heartbeat validates the stream; it does not advance app state
      if (event.type === 'heartbeat') {
        setView((prev) => ({ ...prev, connected: true }))
        return
      }
      setView((prev) => applyEvent(prev, payload))
    }

    const eventTypes = [
      'state_changed',
      'capability_invoked',
      'capability_result',
      'error',
      'heartbeat',
    ] as const

    for (const type of eventTypes) {
      source.addEventListener(type, onTypedEvent)
    }
    source.onmessage = onTypedEvent
    source.onerror = () => {
      setView((prev) => ({ ...prev, connected: false }))
    }

    return () => {
      for (const type of eventTypes) {
        source.removeEventListener(type, onTypedEvent)
      }
      source.onmessage = null
      source.onerror = null
      source.close()
    }
  }, [client, workspaceId, appId, EventSourceCtor])

  return view
}
