import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

describe('App Component', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('renders UI shell successfully', async () => {
    vi.spyOn(global, 'fetch').mockImplementation((url) => {
      if (String(url).includes('/healthz')) {
        return Promise.resolve({ ok: true } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    await act(async () => {
      render(<App />)
    })

    expect(screen.getByText('Traverse Starter')).toBeInTheDocument()
    expect(screen.getByText('Reference UI client for Traverse runtime integration')).toBeInTheDocument()
    expect(screen.getByText('Discovery Endpoint')).toBeInTheDocument()
    expect(screen.getByText('Runtime Status')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Start Workflow', level: 2 })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeInTheDocument()
    expect(screen.getByPlaceholderText(/Enter a note or starter input/i)).toBeInTheDocument()
  })

  it('handles offline runtime status', async () => {
    vi.spyOn(global, 'fetch').mockRejectedValue(new Error('Network error'))

    render(<App />)

    await act(async () => {
      await vi.runOnlyPendingTimersAsync()
    })

    expect(screen.getByText('Offline')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeDisabled()
  })

  it('handles online runtime status', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValue({ ok: true } as Response)

    render(<App />)

    await act(async () => {
      await vi.runOnlyPendingTimersAsync()
    })

    expect(screen.getByText('Online')).toBeInTheDocument()
  })

  it('starts workflow and shows succeeded output', async () => {
    vi.spyOn(global, 'fetch').mockImplementation((url, init) => {
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
          json: () => Promise.resolve({
            execution_id: 'exec-1',
            status: 'succeeded',
            output: { title: 'Runtime title' },
          }),
        } as Response)
      }
      if (path.includes('/traces/exec-1')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([{ event_type: 'completed', timestamp: '2026-01-01T00:00:00Z' }]),
        } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    render(<App />)

    await act(async () => {
      await vi.runOnlyPendingTimersAsync()
    })

    fireEvent.change(screen.getByPlaceholderText(/Enter a note or starter input/i), {
      target: { value: 'Test note' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Start Workflow' }))

    await act(async () => {
      await Promise.resolve()
      await vi.advanceTimersByTimeAsync(1000)
    })

    expect(screen.getByText('Execution succeeded')).toBeInTheDocument()
    expect(screen.getByText(/Runtime title/)).toBeInTheDocument()
    expect(screen.getByText('completed')).toBeInTheDocument()
  })
})
