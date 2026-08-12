import { describe, expect, it } from 'vitest'
import { mapPresentationState } from './mapPresentationState.ts'
import type { EmbedderEventLike } from './types.ts'
import { loadAllFixtureCases, loadFixtureCase } from './loadFixture.ts'

function event(
  partial: Pick<EmbedderEventLike, 'event_type' | 'sequence' | 'data'>,
): EmbedderEventLike {
  return partial
}

describe('mapPresentationState', () => {
  it('returns idle for an empty stream', () => {
    expect(mapPresentationState([])).toEqual({
      state: 'idle',
      errorMessage: null,
      output: null,
    })
  })

  it('maps mid-stream invoke/state to loading', () => {
    const events = [
      event({
        event_type: 'state_changed',
        sequence: 1,
        data: { state: 'running' },
      }),
      event({
        event_type: 'capability_invoked',
        sequence: 2,
        data: { capability_id: 'fixture.process' },
      }),
    ]
    expect(mapPresentationState(events).state).toBe('loading')
  })

  it('matches every catalog fixture expected presentation state', () => {
    for (const fixture of loadAllFixtureCases()) {
      const snapshot = mapPresentationState(fixture.events)
      expect(snapshot.state, fixture.id).toBe(fixture.expected_presentation_state)
      if (fixture.expected_error_message !== undefined) {
        expect(snapshot.errorMessage, fixture.id).toBe(fixture.expected_error_message)
      }
    }
  })

  it('copies output only from capability_result payloads', () => {
    const happy = loadFixtureCase('happy-path.json')
    const snapshot = mapPresentationState(happy.events)
    expect(snapshot.state).toBe('loaded')
    expect(snapshot.output).toEqual({
      title: 'runtime-owned title',
      summary: 'fields come only from the fixture output',
    })
  })

  it('treats late-subscriber prefix replay as equivalent to full map', () => {
    const fixture = loadFixtureCase('replay-late-subscriber.json')
    const full = mapPresentationState(fixture.events)
    let late = mapPresentationState([])
    for (let i = 1; i <= fixture.events.length; i += 1) {
      late = mapPresentationState(fixture.events.slice(0, i))
    }
    expect(late).toEqual(full)
    expect(full.state).toBe('loaded')
  })
})
