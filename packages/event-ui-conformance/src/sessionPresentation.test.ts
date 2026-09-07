import { describe, expect, it } from 'vitest'
import {
  mapSessionPresentation,
  observeSessionPresentation,
  type SessionPresentationHost,
} from './sessionPresentation.ts'
import type { EmbedderEventLike } from './types.ts'

function event(
  partial: Pick<EmbedderEventLike, 'event_type' | 'sequence' | 'data'>,
): EmbedderEventLike {
  return partial
}

describe('mapSessionPresentation', () => {
  it('returns idle for an empty stream', () => {
    expect(mapSessionPresentation([])).toEqual({
      presentationState: 'idle',
      presentationError: null,
      capabilityProgress: [],
      activeCapabilityId: null,
    })
  })

  it('maps mid-stream invoke to loading then result to loaded', () => {
    const mid = [
      event({
        event_type: 'capability_invoked',
        sequence: 1,
        data: { capability_id: 'fixture.process' },
      }),
    ]
    expect(mapSessionPresentation(mid).presentationState).toBe('loading')
    expect(mapSessionPresentation(mid).activeCapabilityId).toBe('fixture.process')

    const done = [
      ...mid,
      event({
        event_type: 'capability_result',
        sequence: 2,
        data: {
          capability_id: 'fixture.process',
          status: 'completed',
          output: { title: 'runtime-owned' },
        },
      }),
    ]
    expect(mapSessionPresentation(done).presentationState).toBe('loaded')
  })

  it('maps fallbackError on empty stream to error', () => {
    const snap = mapSessionPresentation([], { fallbackError: 'submit rejected' })
    expect(snap.presentationState).toBe('error')
    expect(snap.presentationError).toBe('submit rejected')
  })
})

describe('observeSessionPresentation', () => {
  it('starts idle and updates after each subscribed event', () => {
    const listeners: Array<(event: EmbedderEventLike) => void> = []
    const host: SessionPresentationHost = {
      subscribe(listener) {
        listeners.push(listener)
      },
    }
    const states: string[] = []
    observeSessionPresentation(host, (presentation) => {
      states.push(presentation.presentationState)
    })
    expect(states).toEqual(['idle'])

    for (const listener of listeners) {
      listener(
        event({
          event_type: 'capability_invoked',
          sequence: 1,
          data: { capability_id: 'fixture.process' },
        }),
      )
      listener(
        event({
          event_type: 'capability_result',
          sequence: 2,
          data: {
            capability_id: 'fixture.process',
            status: 'completed',
            output: { ok: true },
          },
        }),
      )
    }

    expect(states).toContain('loading')
    expect(states.at(-1)).toBe('loaded')
  })
})
