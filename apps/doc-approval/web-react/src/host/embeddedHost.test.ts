import { describe, it, expect, vi, beforeEach } from 'vitest'
import { EmbedderTestDouble } from 'traverse-embedder-web'
import {
  createTestEmbedder,
  submitDocument,
  initProductionEmbedder,
  DEFAULT_WORKFLOW_ID,
  RUNTIME_MODE_EMBEDDED,
} from './embeddedHost'
import type { DocApprovalOutput } from '../client/traverseOutput'

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

describe('embeddedHost', () => {
  beforeEach(() => {
    initMock.mockReset()
  })

  it('exposes Embedded runtime constants', () => {
    expect(RUNTIME_MODE_EMBEDDED).toBe('Embedded')
    expect(DEFAULT_WORKFLOW_ID).toBe('doc-approval.pipeline')
  })

  it('submitDocument returns scripted output from test double', () => {
    const embedder = createTestEmbedder(sampleOutput)
    const result = submitDocument(embedder, 'Invoice for Acme Corp')
    expect(result.error).toBeNull()
    expect(result.output?.analysis.docType).toBe('invoice')
    expect(result.events.length).toBeGreaterThan(0)
    expect(result.presentationState).toBe('loaded')
    expect(result.capabilityProgress.length).toBeGreaterThan(0)
  })

  it('submitDocument surfaces scripted execution errors', () => {
    const embedder = new EmbedderTestDouble({
      appId: 'doc-approval',
      platform: 'web',
    }).withTargetError(DEFAULT_WORKFLOW_ID, 'execution_failed', 'boom')
    const result = submitDocument(embedder, 'x')
    expect(result.error).toContain('boom')
    expect(result.output).toBeNull()
    expect(result.presentationState).toBe('error')
  })

  it('submitDocument surfaces rejected unknown targets', () => {
    const embedder = new EmbedderTestDouble({ appId: 'doc-approval', platform: 'web' })
    const result = submitDocument(embedder, 'x')
    expect(result.error).toMatch(/target_not_found|rejected/)
  })

  it('initProductionEmbedder returns null when BundleEmbedder.init fails', async () => {
    initMock.mockRejectedValueOnce(new Error('missing bundle'))
    await expect(initProductionEmbedder('/missing.json')).resolves.toBeNull()
  })
})
