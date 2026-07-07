import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

describe('App', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => { vi.useRealTimers(); vi.restoreAllMocks() })

  it('renders UI shell', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    await act(async () => { render(<App />) })
    expect(screen.getByText('Traverse Starter')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Start Workflow', level: 2 })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeInTheDocument()
  })

  it('shows Offline when health check fails', async () => {
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

  it('submits on Cmd+Enter when runtime is online', async () => {
    const output = {
      title: 'T',
      tags: [],
      noteType: 'fleeting',
      suggestedNextAction: 'review',
      status: 'complete',
    }
    vi.spyOn(globalThis, 'fetch').mockImplementation((url, init) => {
      const path = String(url)
      if (path.includes('/healthz')) {
        return Promise.resolve({ ok: true } as Response)
      }
      if (path.includes('/execute') && init?.method === 'POST') {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ execution_id: 'exec-1' }),
        } as Response)
      }
      if (path.includes('/executions/exec-1')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ execution_id: 'exec-1', status: 'succeeded', output }),
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
    await act(async () => { await vi.advanceTimersByTimeAsync(1000) })

    expect(screen.getByText('Title')).toBeInTheDocument()
  })
})
