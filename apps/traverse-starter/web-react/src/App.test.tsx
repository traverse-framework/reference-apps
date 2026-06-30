import { render, screen, act } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from './App'

describe('App', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => { vi.useRealTimers(); vi.restoreAllMocks() })

  it('renders UI shell', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    await act(async () => { render(<App />) })
    expect(screen.getByText('Traverse Starter')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Start Workflow', level: 2 })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeInTheDocument()
  })

  it('shows Offline when health check fails', async () => {
    vi.spyOn(global, 'fetch').mockRejectedValue(new Error('Network error'))
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Offline')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeDisabled()
  })

  it('shows Online when health check succeeds', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValue({ ok: true, json: () => Promise.resolve({}) } as Response)
    render(<App />)
    await act(async () => { await vi.runOnlyPendingTimersAsync() })
    expect(screen.getByText('Online')).toBeInTheDocument()
  })
})
