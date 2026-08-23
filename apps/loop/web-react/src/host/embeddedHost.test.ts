import { describe, it, expect, vi, beforeEach } from 'vitest'
import { EmbedderTestDouble } from 'traverse-embedder-web'
import {
  createTestEmbedder,
  submitTranscript,
  initProductionEmbedder,
  DEFAULT_WORKFLOW_ID,
  RUNTIME_MODE_EMBEDDED,
} from './embeddedHost'
import type { LoopOutput } from '../client/traverseOutput'

const initMock = vi.fn()

vi.mock('traverse-embedder-web', async () => {
  const actual = await vi.importActual<typeof import('traverse-embedder-web')>(
    'traverse-embedder-web',
  )
  return {
    ...actual,
    BundleEmbedder: { init: (...args: unknown[]) => initMock(...args) },
    FetchBundleLoader: actual.FetchBundleLoader,
  }
})

const sampleOutput: LoopOutput = {
  action_items: [{ task: 'Send follow-up email', owner: 'Alex', due: '2026-07-15' }],
  decisions: [{ text: 'Ship Phase 1 this week', made_by: 'Jordan' }],
  follow_ups: ['Schedule design review'],
  summary: 'Team aligned on Phase 1 scope.',
}

describe('embeddedHost', () => {
  beforeEach(() => {
    initMock.mockReset()
  })

  it('exposes Embedded runtime constants', () => {
    expect(RUNTIME_MODE_EMBEDDED).toBe('Embedded')
    expect(DEFAULT_WORKFLOW_ID).toBe('loop.wf1')
  })

  it('submitTranscript returns scripted output from test double', () => {
    const embedder = createTestEmbedder(sampleOutput)
    const result = submitTranscript(embedder, 'Alex will send the follow-up email.')
    expect(result.error).toBeNull()
    expect(result.output?.summary).toBe('Team aligned on Phase 1 scope.')
    expect(result.events.length).toBeGreaterThan(0)
    expect(result.presentationState).toBe('loaded')
    expect(result.capabilityProgress.length).toBeGreaterThan(0)
  })

  it('submitTranscript surfaces scripted execution errors', () => {
    const embedder = new EmbedderTestDouble({
      appId: 'loop',
      platform: 'web',
    }).withTargetError(DEFAULT_WORKFLOW_ID, 'execution_failed', 'boom')
    const result = submitTranscript(embedder, 'x')
    expect(result.error).toContain('boom')
    expect(result.output).toBeNull()
    expect(result.presentationState).toBe('error')
  })

  it('submitTranscript surfaces rejected unknown targets', () => {
    const embedder = new EmbedderTestDouble({ appId: 'loop', platform: 'web' })
    const result = submitTranscript(embedder, 'x')
    expect(result.error).toMatch(/target_not_found|rejected/)
  })

  it('initProductionEmbedder returns null when BundleEmbedder.init fails', async () => {
    initMock.mockRejectedValueOnce(new Error('missing bundle'))
    await expect(initProductionEmbedder('/missing.json')).resolves.toBeNull()
  })
})
