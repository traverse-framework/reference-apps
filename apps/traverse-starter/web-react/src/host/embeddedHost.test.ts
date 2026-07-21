import { describe, it, expect, vi, beforeEach } from 'vitest'
import { EmbedderTestDouble } from 'traverse-embedder-web'
import {
  createTestEmbedder,
  submitNote,
  initProductionEmbedder,
  DEFAULT_WORKFLOW_ID,
  RUNTIME_MODE_EMBEDDED,
} from './embeddedHost'

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

describe('embeddedHost', () => {
  beforeEach(() => {
    initMock.mockReset()
  })

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

  it('submitNote returns error when no capability_result is emitted', () => {
    const embedder = {
      subscribe(cb: (e: { event_type: string; sequence: number; data?: unknown }) => void) {
        // no events
        void cb
      },
      submit() {
        return { status: 'accepted' as const, sessionId: 'sess-1', error: null }
      },
      shutdown() {
        return { killedInstances: 0 }
      },
    }
    const result = submitNote(embedder as never, 'note')
    expect(result.error).toBe('embedder emitted no capability_result')
    expect(result.output).toBeNull()
  })

  it('submitNote reads string error payloads and object error.message', () => {
    const make = (data: unknown) => ({
      subscribe(cb: (e: unknown) => void) {
        cb({
          event_type: 'error',
          sequence: 1,
          session_id: 'sess-1',
          data,
        })
      },
      submit() {
        return { status: 'accepted' as const, sessionId: 'sess-1', error: null }
      },
      shutdown() {
        return { killedInstances: 0 }
      },
    })

    expect(submitNote(make({ error: 'plain' }) as never, 'n').error).toBe('plain')
    expect(
      submitNote(make({ error: { message: 'nested' } }) as never, 'n').error,
    ).toBe('nested')
    expect(submitNote(make({ error: { code: 1 } }) as never, 'n').error).toBe(
      'execution failed',
    )
    expect(submitNote(make(null) as never, 'n').error).toBe('execution failed')
  })

  it('initProductionEmbedder returns embedder on success and null on failure', async () => {
    const fake = { shutdown: () => ({ killedInstances: 0 }) }
    initMock.mockResolvedValueOnce(fake)
    await expect(initProductionEmbedder('/bundles/x')).resolves.toBe(fake)
    expect(initMock).toHaveBeenCalled()

    initMock.mockRejectedValueOnce(new Error('missing bundle'))
    await expect(initProductionEmbedder('/missing')).resolves.toBeNull()
  })
})
