import { describe, expect, it } from 'vitest'
import { EmbedderTestDouble } from 'traverse-embedder-web'
import {
  mapSessionPresentation,
  observeSessionPresentation,
} from './sessionPresentation'

describe('mapSessionPresentation', () => {
  it('maps an empty stream to idle', () => {
    const snap = mapSessionPresentation([])
    expect(snap.presentationState).toBe('idle')
    expect(snap.presentationError).toBeNull()
    expect(snap.capabilityProgress).toEqual([])
    expect(snap.activeCapabilityId).toBeNull()
  })

  it('maps capability invoke/result to loaded with progress', () => {
    const host = new EmbedderTestDouble().withTargetOutput('fixture.process', {
      ok: true,
    })
    const collected: import("traverse-embedder-web").EmbedderEvent[] = []
    host.subscribe((event) => {
      collected.push(event)
    })
    host.submit('fixture.process', { note: 'n' })
    const snap = mapSessionPresentation(collected)
    expect(snap.presentationState).toBe('loaded')
    expect(snap.capabilityProgress.length).toBeGreaterThan(0)
    expect(snap.capabilityProgress.some((s) => s.phase === 'invoked')).toBe(true)
    expect(snap.capabilityProgress.some((s) => s.phase === 'result')).toBe(true)
  })
})

describe('observeSessionPresentation', () => {
  it('replays and updates after submit', () => {
    const host = new EmbedderTestDouble().withTargetOutput('fixture.process', {
      ok: true,
    })
    const states: string[] = []
    observeSessionPresentation(host, (p) => {
      states.push(p.presentationState)
    })
    expect(states.at(-1)).toBe('idle')
    host.submit('fixture.process', { note: 'n' })
    expect(states.at(-1)).toBe('loaded')
  })
})
