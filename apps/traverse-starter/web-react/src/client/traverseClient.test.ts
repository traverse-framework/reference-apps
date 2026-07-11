import { createTraverseClient } from './traverseClient'

const BASE = 'http://127.0.0.1:8787'

function mockFetch(responses: Record<string, unknown>) {
  return vi.fn((url: string) => {
    const key = Object.keys(responses).find(k => url.includes(k))
    if (!key) return Promise.resolve({ ok: false, status: 404 })
    return Promise.resolve({ ok: true, json: () => Promise.resolve(responses[key]) })
  }) as unknown as typeof fetch
}

describe('createTraverseClient', () => {
  it('sendCommand posts and returns accepted envelope', async () => {
    const accepted = {
      api_version: 'v1',
      status: 'accepted',
      workspace_id: 'local-default',
      app_id: 'traverse-starter',
      session_id: 'sess-1',
      command: 'submit',
      state: 'processing',
      execution_id: 'exec-1',
      links: {
        events: '/v1/workspaces/local-default/apps/traverse-starter/events',
      },
    }
    const fetch = mockFetch({ '/commands': accepted })
    globalThis.fetch = fetch
    const result = await createTraverseClient(BASE).sendCommand(
      'local-default',
      'traverse-starter',
      'submit',
      { note: 'hi' },
    )
    expect(result.session_id).toBe('sess-1')
    expect(result.state).toBe('processing')
    expect(fetch).toHaveBeenCalledWith(
      `${BASE}/v1/workspaces/local-default/apps/traverse-starter/commands`,
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('appEventsUrl builds SSE path', () => {
    expect(createTraverseClient(BASE).appEventsUrl('local-default', 'traverse-starter')).toBe(
      `${BASE}/v1/workspaces/local-default/apps/traverse-starter/events`,
    )
  })

  it('fetchTrace returns events', async () => {
    globalThis.fetch = mockFetch({ '/traces/exec-1': [{ event_type: 'start', timestamp: 't0' }] })
    const trace = await createTraverseClient(BASE).fetchTrace('local-default', 'exec-1')
    expect(trace).toHaveLength(1)
  })

  it('sendCommand throws on non-ok response', async () => {
    globalThis.fetch = vi.fn(() => Promise.resolve({ ok: false, status: 422 })) as unknown as typeof fetch
    await expect(
      createTraverseClient(BASE).sendCommand('ws', 'traverse-starter', 'unknown', {}),
    ).rejects.toThrow('sendCommand failed: 422')
  })
})
