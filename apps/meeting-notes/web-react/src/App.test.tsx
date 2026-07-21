import { render, screen, act, fireEvent } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import App from './App'
import { createTestEmbedder } from './host/embeddedHost'
import type { MeetingNotesOutput } from './client/traverseOutput'

const sampleOutput: MeetingNotesOutput = {
  action_items: [{ task: 'Send follow-up email', owner: 'Alex', due: '2026-07-15' }],
  decisions: [{ text: 'Ship Phase 1 this week', made_by: 'Jordan' }],
  follow_ups: ['Schedule design review'],
  summary: 'Team aligned on Phase 1 scope.',
}

describe('App', () => {
  it('renders UI shell with Embedded zone 1', () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    expect(screen.getByText('Meeting Notes')).toBeInTheDocument()
    expect(screen.getByText('Embedded')).toBeInTheDocument()
    expect(screen.getByText('Ready')).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Meeting Transcript', level: 2 })).toBeInTheDocument()
  })

  it('shows Unavailable when embedder is null', () => {
    render(<App embedder={null} />)
    expect(screen.getByText('Unavailable')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Process Transcript' })).toBeDisabled()
    expect(screen.getByText(/sync the meeting-notes bundle/)).toBeInTheDocument()
  })

  it('submits transcript via test double and displays list fields', async () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    fireEvent.change(screen.getByPlaceholderText(/Paste the full meeting transcript/i), {
      target: { value: 'Alex will send the follow-up email.' },
    })
    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'Process Transcript' }))
    })
    expect(screen.getByText('Send follow-up email')).toBeInTheDocument()
    expect(screen.getByText('Ship Phase 1 this week')).toBeInTheDocument()
    expect(screen.getByText('Schedule design review')).toBeInTheDocument()
    expect(screen.getByText('Team aligned on Phase 1 scope.')).toBeInTheDocument()
  })

  it('reset returns to idle', async () => {
    render(<App embedder={createTestEmbedder(sampleOutput)} />)
    fireEvent.change(screen.getByPlaceholderText(/Paste the full meeting transcript/i), {
      target: { value: 'notes' },
    })
    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'Process Transcript' }))
    })
    fireEvent.click(screen.getByRole('button', { name: 'Reset' }))
    expect(screen.getByText(/Submit a transcript above/)).toBeInTheDocument()
  })
})
