import { renderHook, act } from '@testing-library/react'
import { useExecution } from './useExecution'
import type { TraverseClient, ExecutionResult } from '../client/traverseClient'

function makeClient(overrides: Partial<TraverseClient> = {}): TraverseClient {
  return {
    execute: vi.fn().mockResolvedValue({ executionId: 'exec-1' }),
    pollExecution: vi.fn().mockResolvedValue({
      execution_id: 'exec-1',
      status: 'succeeded',
      output: 'ok',
    } as ExecutionResult),
    fetchTrace: vi.fn().mockResolvedValue([]),
    ...overrides,
  }
}

const POLL_MS = 10

describe('useExecution', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => vi.useRealTimers())

  it('starts idle', () => {
    const { result } = renderHook(() => useExecution(makeClient(), 'ws', POLL_MS))
    expect(result.current.state.phase).toBe('idle')
  })

  it('transitions loading → succeeded via polling', async () => {
    const client = makeClient()
    const { result } = renderHook(() => useExecution(client, 'ws', POLL_MS))

    act(() => { result.current.run('traverse-starter', { text: 'hi' }) })
    expect(result.current.state.phase).toBe('loading')

    await act(async () => { await Promise.resolve() })
    expect(result.current.state.phase).toBe('polling')

    await act(async () => { await vi.advanceTimersByTimeAsync(POLL_MS) })
    expect(result.current.state.phase).toBe('succeeded')
  })

  it('transitions to succeeded on synchronous execute response', async () => {
    const client = makeClient({
      execute: vi.fn().mockResolvedValue({
        result: { status: 'succeeded', output: { title: 'Note' } },
      }),
    })
    const { result } = renderHook(() => useExecution(client, 'ws', POLL_MS))

    await act(async () => {
      result.current.run('traverse-starter', { text: 'hi' })
      await Promise.resolve()
    })

    expect(result.current.state.phase).toBe('succeeded')
  })

  it('transitions to failed when execute throws', async () => {
    const client = makeClient({
      execute: vi.fn().mockRejectedValue(new Error('net error')),
    })
    const { result } = renderHook(() => useExecution(client, 'ws', POLL_MS))

    await act(async () => {
      result.current.run('traverse-starter', { text: 'hi' })
      await Promise.resolve()
    })

    expect(result.current.state.phase).toBe('failed')
    expect((result.current.state as { phase: 'failed'; error: string }).error).toContain('net error')
  })

  it('transitions to failed when poll returns failed status', async () => {
    const client = makeClient({
      pollExecution: vi.fn().mockResolvedValue({
        execution_id: 'exec-1',
        status: 'failed',
        error: 'boom',
      } as ExecutionResult),
    })
    const { result } = renderHook(() => useExecution(client, 'ws', POLL_MS))

    act(() => { result.current.run('traverse-starter', { text: 'hi' }) })
    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(POLL_MS) })

    expect(result.current.state.phase).toBe('failed')
    expect((result.current.state as { phase: 'failed'; error: string }).error).toBe('boom')
  })
})
