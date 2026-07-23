import { describe, it, expect } from 'vitest'
import { EmbedderTestDouble } from 'traverse-embedder-web'
import {
  createEmbeddedTraceClient,
  EMBEDDED_TRACE_API_VERSION,
  summaryPreview,
} from './traceClient'

describe('createEmbeddedTraceClient', () => {
  it('lists and gets traces after a successful submit', () => {
    const api = new EmbedderTestDouble().withTargetOutput('fixture.success', { ok: true })
    api.submit('fixture.success', { note: 'hello' })
    const client = createEmbeddedTraceClient(api)

    expect(client.apiVersion()).toBe(EMBEDDED_TRACE_API_VERSION)
    const page = client.list(10)
    expect(page.summaries.length).toBeGreaterThan(0)
    const detail = client.get(page.summaries[0].traceId)
    expect(detail.summary.traceId).toBe(page.summaries[0].traceId)
    expect(detail.summary.outcome).toBe('completed')
  })

  it('surfaces public error codes', () => {
    const api = new EmbedderTestDouble()
    const client = createEmbeddedTraceClient(api)
    expect(() => client.get('missing-trace')).toThrow(/trace_not_found/)
  })
})

describe('summaryPreview', () => {
  it('formats outcome and target', () => {
    expect(
      summaryPreview({
        traceId: 't1',
        executionId: 'e1',
        targetId: 'fixture.success',
        completedAt: '2026-01-01T00:00:00.000Z',
        completionSequence: 1,
        outcome: 'completed',
      }),
    ).toContain('completed')
  })
})
