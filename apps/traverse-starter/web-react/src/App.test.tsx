import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

type Listener = (event: MessageEvent<string>) => void

class MockEventSource {
  static instances: MockEventSource[] = []
  url: string
  onmessage: Listener | null = null
  onerror: ((event: Event) => void) | null = null
  private listeners = new Map<string, Set<Listener>>()

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

  close() {}

  emit(type: string, data: unknown) {
    const event = { type, data: JSON.stringify(data) } as MessageEvent<string>
    for (const listener of this.listeners.get(type) ?? []) listener(event)
  }

  static reset() {
    MockEventSource.instances = []
  }
}

describe('App', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    MockEventSource.reset()
    vi.stubGlobal('EventSource', MockEventSource)
  })
  afterEach(() => {
    vi.useRealTimers()
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('renders UI shell', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    await act(async () => { render(<App />) })
    expect(screen.getByText('Traverse Starter')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Start Workflow', level: 2 })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeInTheDocument()
  })

  it('shows offline when health check fails', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Network error'))
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Offline')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeDisabled()
    expect(screen.getByText(/The runtime is offline/)).toBeInTheDocument()
    expect(screen.getByText(/Connect to the Traverse runtime/)).toBeInTheDocument()
  })

  it('shows Online when health check succeeds', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Online')).toBeInTheDocument()
  })

  it('shows character count for note input', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true } as Response)
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    fireEvent.change(screen.getByPlaceholderText(/Enter a note/i), { target: { value: 'hello' } })
    expect(screen.getByText('5 / 2000')).toBeInTheDocument()
  })

  it('submits on Cmd+Enter and renders SSE capability_result output', async () => {
    const output = {
      validate: { valid: true, issues: [] as string[] },
      process: {
        title: 'T',
        tags: [],
        noteType: 'fleeting',
        suggestedNextAction: 'review',
        status: 'complete',
      },
      summarize: { summary: 'Short', wordCount: 1 },
    }
    vi.spyOn(globalThis, 'fetch').mockImplementation((url, init) => {
      const path = String(url)
      if (path.includes('/healthz')) {
        return Promise.resolve({ ok: true } as Response)
      }
      if (path.includes('/commands') && init?.method === 'POST') {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            api_version: 'v1',
            status: 'accepted',
            workspace_id: 'local-default',
            app_id: 'traverse-starter',
            session_id: 'sess-1',
            command: 'submit',
            state: 'processing',
            execution_id: 'exec-1',
            links: {},
          }),
        } as Response)
      }
      if (path.includes('/traces/exec-1')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([]),
        } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })

    const textarea = screen.getByPlaceholderText(/Enter a note/i)
    fireEvent.change(textarea, { target: { value: 'Test note' } })
    fireEvent.keyDown(textarea, { key: 'Enter', metaKey: true })

    await act(async () => { await Promise.resolve() })

    const source = MockEventSource.instances.at(-1)
    expect(source).toBeTruthy()
    act(() => {
      source!.emit('capability_result', {
        session_id: 'sess-1',
        execution_id: 'exec-1',
        state: 'results',
        previous_state: 'processing',
        output,
      })
    })

    expect(screen.getByText('Title')).toBeInTheDocument()
    expect(screen.getByText('T')).toBeInTheDocument()
    expect(screen.getByText('Summary')).toBeInTheDocument()
    expect(screen.getByText('Short')).toBeInTheDocument()
  })
})
