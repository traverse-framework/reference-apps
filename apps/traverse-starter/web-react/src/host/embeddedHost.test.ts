import { describe, it, expect } from 'vitest'
import { EmbedderTestDouble } from 'traverse-embedder-web'
import {
  createTestEmbedder,
  submitNote,
  DEFAULT_WORKFLOW_ID,
  RUNTIME_MODE_EMBEDDED,
} from './embeddedHost'

describe('embeddedHost', () => {
  it('exposes Embedded runtime constants', () => {
    expect(RUNTIME_MODE_EMBEDDED).toBe('Embedded')
    expect(DEFAULT_WORKFLOW_ID).toBe('traverse-starter.pipeline')
  })

  it('submitNote returns scripted pipeline output from test double', () => {
    const output = {
      validate: { valid: true, issues: [] as string[] },
      process: {
        title: 'Hello',
        tags: ['a'],
        noteType: 'note',
        suggestedNextAction: 'next',
        status: 'ok',
      },
      summarize: { summary: 'Sum', wordCount: 1 },
    }
    const embedder = createTestEmbedder(output)
    const result = submitNote(embedder, 'note text')
    expect(result.error).toBeNull()
    expect(result.output?.process.title).toBe('Hello')
    expect(result.events.length).toBeGreaterThan(0)
  })

  it('submitNote surfaces scripted execution errors', () => {
    const embedder = new EmbedderTestDouble({
      appId: 'traverse-starter',
      platform: 'web',
    }).withTargetError(DEFAULT_WORKFLOW_ID, 'execution_failed', 'boom')
    const result = submitNote(embedder, 'x')
    expect(result.error).toContain('boom')
    expect(result.output).toBeNull()
  })

  it('submitNote surfaces rejected unknown targets', () => {
    const embedder = new EmbedderTestDouble({ appId: 'traverse-starter', platform: 'web' })
    const result = submitNote(embedder, 'x')
    expect(result.error).toMatch(/target_not_found|rejected/)
  })
})
