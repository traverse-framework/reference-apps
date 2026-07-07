import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

describe('App', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => { vi.useRealTimers(); vi.restoreAllMocks() })

  it('renders UI shell', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    await act(async () => { render(<App />) })
    expect(screen.getByText('Doc Approval')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Submit Document', level: 2 })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Analyze Document' })).toBeInTheDocument()
  })

  it('shows Offline when health check fails', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Network error'))
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Offline')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Analyze Document' })).toBeDisabled()
    expect(screen.getByText(/The runtime is offline/)).toBeInTheDocument()
  })

  it('shows Online when health check succeeds', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Online')).toBeInTheDocument()
  })

  it('submits document and displays analysis fields', async () => {
    const output = {
      docType: 'invoice',
      parties: ['Acme Corp'],
      amounts: ['$500.00'],
      confidence: 0.88,
      recommendation: 'approve',
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
        return Promise.resolve({ ok: true, json: () => Promise.resolve([]) } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })

    fireEvent.change(screen.getByPlaceholderText(/Paste or type document/i), { target: { value: 'Invoice #123' } })
    fireEvent.click(screen.getByRole('button', { name: 'Analyze Document' }))

    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(1000) })

    expect(screen.getByText('Document Type')).toBeInTheDocument()
    expect(screen.getByText('invoice')).toBeInTheDocument()
    expect(screen.getByText('88%')).toBeInTheDocument()
  })

  it('reset returns to idle', async () => {
    const output = {
      docType: 'invoice',
      parties: [],
      amounts: [],
      confidence: 0.5,
      recommendation: 'review',
    }
    vi.spyOn(globalThis, 'fetch').mockImplementation((url) => {
      const path = String(url)
      if (path.includes('/healthz')) return Promise.resolve({ ok: true } as Response)
      if (path.includes('/execute')) {
        return Promise.resolve({ ok: true, json: () => Promise.resolve({ execution_id: 'exec-1' }) } as Response)
      }
      if (path.includes('/executions/exec-1')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ execution_id: 'exec-1', status: 'succeeded', output }),
        } as Response)
      }
      if (path.includes('/traces/exec-1')) {
        return Promise.resolve({ ok: true, json: () => Promise.resolve([]) } as Response)
      }
      return Promise.resolve({ ok: false, status: 404 } as Response)
    })

    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    fireEvent.change(screen.getByPlaceholderText(/Paste or type document/i), { target: { value: 'doc' } })
    fireEvent.click(screen.getByRole('button', { name: 'Analyze Document' }))
    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(1000) })

    fireEvent.click(screen.getByRole('button', { name: 'Reset' }))
    expect(screen.getByText(/Submit a document above/)).toBeInTheDocument()
  })
})
