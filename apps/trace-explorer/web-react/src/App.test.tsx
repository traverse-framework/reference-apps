import { render, screen, act, waitFor } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { EmbedderTestDouble } from 'traverse-embedder-web'
import App from './App'

describe('App', () => {
  it('renders empty embedded state without HTTP', async () => {
    await act(async () => {
      render(<App host={new EmbedderTestDouble()} />)
    })
    expect(screen.getByText('Trace Explorer')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getByText(/No retained traces/)).toBeInTheDocument()
    })
    expect(screen.getByText('Embedded Trace API')).toBeInTheDocument()
  })

  it('lists a trace after the host records a submit', async () => {
    const host = new EmbedderTestDouble().withTargetOutput('fixture.success', { ok: true })
    host.submit('fixture.success', { note: 'n' })
    await act(async () => {
      render(<App host={host} />)
    })
    await waitFor(() => {
      expect(screen.getByText(/fixture\.success/)).toBeInTheDocument()
    })
  })
})
