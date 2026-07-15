import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import App from './App'
import { createTestEmbedder } from './host/embeddedHost'
import type { TraverseStarterOutput } from './client/traverseOutput'

const sampleOutput: TraverseStarterOutput = {
  validate: { valid: true, issues: [] },
  process: {
    title: 'T',
    tags: ['tag'],
    noteType: 'fleeting',
    suggestedNextAction: 'review',
    status: 'complete',
  },
  summarize: { summary: 'Short', wordCount: 1 },
}

describe('App', () => {
  it('renders UI shell with Embedded zone 1', () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    expect(screen.getByText('Traverse Starter')).toBeInTheDocument()
    expect(screen.getByText('Embedded')).toBeInTheDocument()
    expect(screen.getByText('Ready')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Start Workflow', level: 2 })).toBeInTheDocument()
  })

  it('shows Unavailable when embedder is null', () => {
    render(<App embedder={null} />)
    expect(screen.getByText('Unavailable')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Start Workflow' })).toBeDisabled()
    expect(screen.getByText(/Embedded runtime unavailable/)).toBeInTheDocument()
  })

  it('shows character count for note input', () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    fireEvent.change(screen.getByPlaceholderText(/Enter a note/i), { target: { value: 'hello' } })
    expect(screen.getByText('5 / 2000')).toBeInTheDocument()
  })

  it('submits via embedder test double and renders pipeline output', async () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    const textarea = screen.getByPlaceholderText(/Enter a note/i)
    fireEvent.change(textarea, { target: { value: 'Test note' } })
    await act(async () => {
      fireEvent.keyDown(textarea, { key: 'Enter', metaKey: true })
    })
    expect(screen.getByText('Title')).toBeInTheDocument()
    expect(screen.getByText('T')).toBeInTheDocument()
    expect(screen.getByText('Summary')).toBeInTheDocument()
    expect(screen.getByText('Short')).toBeInTheDocument()
  })
})
