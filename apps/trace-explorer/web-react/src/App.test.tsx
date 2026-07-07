import { render, screen, act } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

describe('App', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => { vi.useRealTimers(); vi.restoreAllMocks() })

  it('renders empty state', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue({ ok: true } as Response)
    await act(async () => { render(<App />) })
    expect(screen.getByText('Trace Explorer')).toBeInTheDocument()
    expect(screen.getByText(/Paste an execution ID above/)).toBeInTheDocument()
  })

  it('shows offline when health check fails', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('offline'))
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Offline')).toBeInTheDocument()
  })
})
