import { renderHook, act } from '@testing-library/react'
import { useAppState } from './useAppState'
import type { TraverseClient } from '../client/traverseClient'

type Listener = (event: MessageEvent<string>) => void

class MockEventSource {
  static instances: MockEventSource[] = []
  url: string
  onmessage: Listener | null = null
  onerror: ((event: Event) => void) | null = null
  private listeners = new Map<string, Set<Listener>>()
  readyState = 1

  constructor(url: string) {
    this.url = url
    MockEventSource.instances.push(this)
  }

  addEventListener(type: string, listener: EventListenerOrEventListenerObject) {
    const fn = listener as Listener
    const set = this.listeners.get(type) ?? new Set()
    set.add(fn)
    this.listeners.set(type, set)
  }

  removeEventListener(type: string, listener: EventListenerOrEventListenerObject) {
    this.listeners.get(type)?.delete(listener as Listener)
  }

  close() {
    this.readyState = 2
  }

  emit(type: string, data: unknown) {
    const event = {
      type,
      data: JSON.stringify(data),
    } as MessageEvent<string>
    const set = this.listeners.get(type)
    if (set) {
      for (const listener of set) listener(event)
    }
    if (type === 'message' && this.onmessage) {
      this.onmessage(event)
    }
  }

  static reset() {
    MockEventSource.instances = []
  }
}

function makeClient(): TraverseClient {
  return {
    sendCommand: vi.fn(),
    appEventsUrl: (workspaceId, appId) =>
      `http://127.0.0.1:8787/v1/workspaces/${workspaceId}/apps/${appId}/events`,
    fetchTrace: vi.fn().mockResolvedValue([]),
  }
}

function latestSource(): MockEventSource {
  const source = MockEventSource.instances.at(-1)
  if (!source) throw new Error('expected EventSource instance')
  return source
}

describe('useAppState', () => {
  beforeEach(() => {
    MockEventSource.reset()
  })

  it('starts idle and disconnected', () => {
    const client = makeClient()
    const { result } = renderHook(() =>
      useAppState(client, 'ws', 'traverse-starter', MockEventSource as unknown as typeof EventSource),
    )
    expect(result.current.state).toBe('idle')
    expect(result.current.connected).toBe(false)
    expect(latestSource().url).toContain('/apps/traverse-starter/events')
  })

  it('marks connected on heartbeat without changing state', () => {
    const client = makeClient()
    const { result } = renderHook(() =>
      useAppState(client, 'ws', 'traverse-starter', MockEventSource as unknown as typeof EventSource),
    )

    act(() => {
      latestSource().emit('heartbeat', { app_id: 'traverse-starter' })
    })

    expect(result.current.connected).toBe(true)
    expect(result.current.state).toBe('idle')
  })

  it('maps state_changed and capability_result payloads to render state', () => {
    const client = makeClient()
    const { result } = renderHook(() =>
      useAppState(client, 'ws', 'traverse-starter', MockEventSource as unknown as typeof EventSource),
    )
    const source = latestSource()

    act(() => {
      source.emit('state_changed', {
        session_id: 'sess-1',
        execution_id: 'exec-1',
        state: 'processing',
        previous_state: 'idle',
      })
    })
    expect(result.current.state).toBe('processing')
    expect(result.current.sessionId).toBe('sess-1')
    expect(result.current.executionId).toBe('exec-1')

    act(() => {
      source.emit('capability_result', {
        session_id: 'sess-1',
        execution_id: 'exec-1',
        state: 'results',
        previous_state: 'processing',
        output: { title: 'T', tags: [], noteType: 'fleeting', suggestedNextAction: 'review', status: 'complete' },
      })
    })
    expect(result.current.state).toBe('results')
    expect(result.current.output).toEqual(
      expect.objectContaining({ title: 'T' }),
    )
  })

  it('maps error events to error state and message', () => {
    const client = makeClient()
    const { result } = renderHook(() =>
      useAppState(client, 'ws', 'traverse-starter', MockEventSource as unknown as typeof EventSource),
    )

    act(() => {
      latestSource().emit('error', {
        state: 'error',
        previous_state: 'processing',
        error: { code: 'failed', message: 'boom' },
      })
    })

    expect(result.current.state).toBe('error')
    expect(result.current.error).toBe('boom')
  })

  it('closes EventSource on unmount', () => {
    const client = makeClient()
    const { unmount } = renderHook(() =>
      useAppState(client, 'ws', 'traverse-starter', MockEventSource as unknown as typeof EventSource),
    )
    const source = latestSource()
    unmount()
    expect(source.readyState).toBe(2)
  })
})
