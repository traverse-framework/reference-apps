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
  it('execute posts and returns execution_id', async () => {
    const fetch = mockFetch({ '/execute': { execution_id: 'exec-1' } })
    global.fetch = fetch
    const id = await createTraverseClient(BASE).execute('local-default', 'cap.foo', { note: 'hi' })
    expect(id).toBe('exec-1')
    expect(fetch).toHaveBeenCalledWith(
      `${BASE}/v1/workspaces/local-default/execute`,
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('pollExecution returns result', async () => {
    global.fetch = mockFetch({ '/executions/exec-1': { execution_id: 'exec-1', status: 'succeeded', output: { title: 'T' } } })
    const result = await createTraverseClient(BASE).pollExecution('local-default', 'exec-1')
    expect(result.status).toBe('succeeded')
  })

  it('fetchTrace returns events', async () => {
    global.fetch = mockFetch({ '/traces/exec-1': [{ event_type: 'start', timestamp: 't0' }] })
    const trace = await createTraverseClient(BASE).fetchTrace('local-default', 'exec-1')
    expect(trace).toHaveLength(1)
  })

  it('execute throws on non-ok response', async () => {
    global.fetch = vi.fn(() => Promise.resolve({ ok: false, status: 500 })) as unknown as typeof fetch
    await expect(createTraverseClient(BASE).execute('ws', 'cap', {})).rejects.toThrow('execute failed: 500')
  })
})
