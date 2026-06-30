import { renderHook, act } from '@testing-library/react'
import { useExecution } from './useExecution'
import type { TraverseClient, ExecutionResult } from '../client/traverseClient'

function makeClient(overrides: Partial<TraverseClient> = {}): TraverseClient {
  return {
    execute: vi.fn().mockResolvedValue('exec-1'),
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

    act(() => { result.current.run('cap', {}) })
    expect(result.current.state.phase).toBe('loading')

    // flush execute promise, interval not yet fired
    await act(async () => { await Promise.resolve() })
    expect(result.current.state.phase).toBe('polling')

    // fire the poll interval
    await act(async () => { await vi.advanceTimersByTimeAsync(POLL_MS) })
    expect(result.current.state.phase).toBe('succeeded')
  })

  it('transitions to failed when execute throws', async () => {
    const client = makeClient({
      execute: vi.fn().mockRejectedValue(new Error('net error')),
    })
    const { result } = renderHook(() => useExecution(client, 'ws', POLL_MS))

    await act(async () => {
      result.current.run('cap', {})
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

    act(() => { result.current.run('cap', {}) })
    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(POLL_MS) })

    expect(result.current.state.phase).toBe('failed')
    expect((result.current.state as { phase: 'failed'; error: string }).error).toBe('boom')
  })
})
