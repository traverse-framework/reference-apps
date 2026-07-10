import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

const sampleOutput = {
  action_items: [
    { task: 'Send follow-up email', owner: 'Alex', due: '2026-07-15' },
  ],
  decisions: [
    { text: 'Ship Phase 1 this week', made_by: 'Jordan' },
  ],
  follow_ups: ['Schedule design review'],
  summary: 'Team aligned on Phase 1 scope.',
}

const emptyListsOutput = {
  action_items: [],
  decisions: [],
  follow_ups: [],
  summary: 'Quiet meeting.',
}

describe('App', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => { vi.useRealTimers(); vi.restoreAllMocks() })

  it('renders UI shell', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    await act(async () => { render(<App />) })
    expect(screen.getByText('Meeting Notes')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Meeting Transcript', level: 2 })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Process Transcript' })).toBeInTheDocument()
  })

  it('shows offline when health check fails', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Network error'))
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Offline')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Process Transcript' })).toBeDisabled()
    expect(screen.getByText(/The runtime is offline/)).toBeInTheDocument()
  })

  it('shows Online when health check succeeds', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Online')).toBeInTheDocument()
  })

  it('submits transcript and displays all four output sections', async () => {
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
          json: () => Promise.resolve({ execution_id: 'exec-1', status: 'succeeded', output: sampleOutput }),
        } as Response)
      }
      if (path.includes('/traces/exec-1')) {
        return Promise.resolve({ ok: true, json: () => Promise.resolve([]) } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })

    fireEvent.change(screen.getByPlaceholderText(/Paste the full meeting transcript/i), {
      target: { value: 'Alex will send the follow-up email.' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Process Transcript' }))

    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(1000) })

    expect(screen.getByText('Action Items')).toBeInTheDocument()
    expect(screen.getByText('Send follow-up email')).toBeInTheDocument()
    expect(screen.getByText('Alex')).toBeInTheDocument()
    expect(screen.getByText('due 2026-07-15')).toBeInTheDocument()
    expect(screen.getByText('Decisions')).toBeInTheDocument()
    expect(screen.getByText('Ship Phase 1 this week')).toBeInTheDocument()
    expect(screen.getByText(/decided by Jordan/)).toBeInTheDocument()
    expect(screen.getByText('Follow-ups')).toBeInTheDocument()
    expect(screen.getByText('Schedule design review')).toBeInTheDocument()
    expect(screen.getByText('Summary')).toBeInTheDocument()
    expect(screen.getByText('Team aligned on Phase 1 scope.')).toBeInTheDocument()
  })

  it('renders None recorded for empty arrays', async () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation((url) => {
      const path = String(url)
      if (path.includes('/healthz')) return Promise.resolve({ ok: true } as Response)
      if (path.includes('/execute')) {
        return Promise.resolve({ ok: true, json: () => Promise.resolve({ execution_id: 'exec-1' }) } as Response)
      }
      if (path.includes('/executions/exec-1')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ execution_id: 'exec-1', status: 'succeeded', output: emptyListsOutput }),
        } as Response)
      }
      if (path.includes('/traces/exec-1')) {
        return Promise.resolve({ ok: true, json: () => Promise.resolve([]) } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    fireEvent.change(screen.getByPlaceholderText(/Paste the full meeting transcript/i), {
      target: { value: 'No action items today.' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Process Transcript' }))
    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(1000) })

    expect(screen.getAllByText('None recorded')).toHaveLength(3)
    expect(screen.getByText('Quiet meeting.')).toBeInTheDocument()
  })

  it('reset returns to idle', async () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation((url) => {
      const path = String(url)
      if (path.includes('/healthz')) return Promise.resolve({ ok: true } as Response)
      if (path.includes('/execute')) {
        return Promise.resolve({ ok: true, json: () => Promise.resolve({ execution_id: 'exec-1' }) } as Response)
      }
      if (path.includes('/executions/exec-1')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ execution_id: 'exec-1', status: 'succeeded', output: emptyListsOutput }),
        } as Response)
      }
      if (path.includes('/traces/exec-1')) {
        return Promise.resolve({ ok: true, json: () => Promise.resolve([]) } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    fireEvent.change(screen.getByPlaceholderText(/Paste the full meeting transcript/i), {
      target: { value: 'notes' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Process Transcript' }))
    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(1000) })

    fireEvent.click(screen.getByRole('button', { name: 'Reset' }))
    expect(screen.getByText(/Submit a transcript above/)).toBeInTheDocument()
  })
})
