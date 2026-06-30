import { createTraverseClient } from './traverseClient'

const BASE = 'http://127.0.0.1:8787'

function mockFetch(responses: Record<string, unknown>) {
  return vi.fn((url: string) => {
    const key = Object.keys(responses).find(k => url.includes(k))
    if (!key) return Promise.resolve({ ok: false, status: 404 })
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve(responses[key]),
    })
  }) as unknown as typeof fetch
}

describe('createTraverseClient', () => {
  it('execute posts capability_id and returns execution_id', async () => {
    const fetch = mockFetch({ '/execute': { execution_id: 'exec-1' } })
    global.fetch = fetch
    const client = createTraverseClient(BASE)
    const response = await client.execute('local-default', 'traverse-starter', { text: 'hi' })
    expect(response.executionId).toBe('exec-1')
    expect(fetch).toHaveBeenCalledWith(
      `${BASE}/v1/workspaces/local-default/execute`,
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ capability_id: 'traverse-starter', input: { text: 'hi' } }),
      }),
    )
  })

  it('execute returns inline result for synchronous completion', async () => {
    const fetch = mockFetch({
      '/execute': { status: 'succeeded', output: { title: 'Note' } },
    })
    global.fetch = fetch
    const client = createTraverseClient(BASE)
    const response = await client.execute('local-default', 'traverse-starter', { text: 'hi' })
    expect(response.result?.status).toBe('succeeded')
    expect(response.executionId).toBeUndefined()
  })

  it('pollExecution returns result', async () => {
    const fetch = mockFetch({ '/executions/exec-1': { execution_id: 'exec-1', status: 'succeeded', output: 42 } })
    global.fetch = fetch
    const client = createTraverseClient(BASE)
    const result = await client.pollExecution('local-default', 'exec-1')
    expect(result.status).toBe('succeeded')
    expect(result.output).toBe(42)
  })

  it('fetchTrace returns events array', async () => {
    const fetch = mockFetch({ '/traces/exec-1': [{ event_type: 'start', timestamp: 't0' }] })
    global.fetch = fetch
    const client = createTraverseClient(BASE)
    const trace = await client.fetchTrace('local-default', 'exec-1')
    expect(trace).toHaveLength(1)
    expect(trace[0].event_type).toBe('start')
  })

  it('execute throws on non-ok response', async () => {
    global.fetch = vi.fn(() => Promise.resolve({ ok: false, status: 500 })) as unknown as typeof fetch
    const client = createTraverseClient(BASE)
    await expect(client.execute('ws', 'cap', {})).rejects.toThrow('execute failed: 500')
  })
})
