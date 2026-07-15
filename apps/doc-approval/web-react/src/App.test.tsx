import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import App from './App'
import { createTestEmbedder } from './host/embeddedHost'
import type { DocApprovalOutput } from './client/traverseOutput'

const sampleOutput: DocApprovalOutput = {
  analysis: {
    docType: 'invoice',
    parties: ['Acme Corp'],
    amounts: ['$500.00'],
    confidence: '0.88',
    recommendation: 'approve',
  },
  recommendation: {
    recommendation: 'approve',
    rationale: 'Amounts within policy',
    confidence: 'high',
  },
}

describe('App', () => {
  it('renders UI shell with Embedded zone 1', () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    expect(screen.getByText('Doc Approval')).toBeInTheDocument()
    expect(screen.getByText('Embedded')).toBeInTheDocument()
    expect(screen.getByText('Ready')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Submit Document', level: 2 })).toBeInTheDocument()
  })

  it('shows Unavailable when embedder is null', () => {
    render(<App embedder={null} />)
    expect(screen.getByText('Unavailable')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Analyze Document' })).toBeDisabled()
    expect(screen.getByText(/sync the doc-approval bundle/)).toBeInTheDocument()
  })

  it('submits document via test double and displays pipeline fields', async () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    fireEvent.change(screen.getByPlaceholderText(/Paste or type document/i), {
      target: { value: 'Invoice #123' },
    })
    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'Analyze Document' }))
    })
    expect(screen.getByText('Document Type')).toBeInTheDocument()
    expect(screen.getByText('invoice')).toBeInTheDocument()
    expect(screen.getByText('Amounts within policy')).toBeInTheDocument()
    expect(screen.getByText('high')).toBeInTheDocument()
  })

  it('reset returns to idle', async () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    fireEvent.change(screen.getByPlaceholderText(/Paste or type document/i), {
      target: { value: 'doc' },
    })
    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'Analyze Document' }))
    })
    fireEvent.click(screen.getByRole('button', { name: 'Reset' }))
    expect(screen.getByText(/Submit a document above/)).toBeInTheDocument()
  })
})
