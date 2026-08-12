import { describe, expect, it } from 'vitest'
import { activeCapabilityId, mapCapabilityProgress } from './capabilityProgress.ts'
import { loadFixtureCase } from './loadFixture.ts'
import { mapPresentationState } from './mapPresentationState.ts'
import type { EmbedderEventLike } from './types.ts'

describe('mapCapabilityProgress', () => {
  it('reflects invoke/result order for multi-capability fixtures', () => {
    const fixture = loadFixtureCase('multi-capability.json')
    const progress = mapCapabilityProgress(fixture.events)
    expect(progress.map((step) => ({ capability_id: step.capabilityId, phase: step.phase }))).toEqual(
      fixture.expected_capability_order,
    )

    const snapshot = mapPresentationState(fixture.events)
    expect(snapshot.state).toBe('loaded')
    expect(snapshot.output).toEqual({ recommendation: 'runtime-owned recommendation' })
    expect(activeCapabilityId(fixture.events)).toBeNull()
  })

  it('keeps loading and active capability when invoke has no result yet', () => {
    const events: EmbedderEventLike[] = [
      {
        event_type: 'capability_invoked',
        sequence: 1,
        data: { capability_id: 'fixture.process', capability_version: '1.0.0' },
      },
    ]
    expect(mapPresentationState(events).state).toBe('loading')
    expect(activeCapabilityId(events)).toBe('fixture.process')
    expect(mapCapabilityProgress(events)).toEqual([
      {
        capabilityId: 'fixture.process',
        phase: 'invoked',
        sequence: 1,
        status: null,
        output: null,
      },
    ])
  })
})
