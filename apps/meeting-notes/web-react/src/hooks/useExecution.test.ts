import { renderHook, act } from '@testing-library/react'
import { useExecution } from './useExecution'
import type { TraverseClient, ExecutionResult } from '../client/traverseClient'

function makeClient(overrides: Partial<TraverseClient> = {}): TraverseClient {
  return {
    execute: vi.fn().mockResolvedValue('exec-1'),
    pollExecution: vi.fn().mockResolvedValue({
      execution_id: 'exec-1',
      status: 'succeeded',
      output: { docType: 'invoice', parties: [], amounts: [], confidence: 0.9, recommendation: 'approve' },
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

  it('transitions loading → polling → succeeded', async () => {
    const { result } = renderHook(() => useExecution(makeClient(), 'ws', POLL_MS))

    act(() => { result.current.run('doc-approval.analyze', { document: 'text' }) })
    expect(result.current.state.phase).toBe('loading')

    await act(async () => { await Promise.resolve() })
    expect(result.current.state.phase).toBe('polling')

    await act(async () => { await vi.advanceTimersByTimeAsync(POLL_MS) })
    expect(result.current.state.phase).toBe('succeeded')
  })

  it('reset returns to idle', async () => {
    const { result } = renderHook(() => useExecution(makeClient(), 'ws', POLL_MS))

    act(() => { result.current.run('doc-approval.analyze', { document: 'text' }) })
    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(POLL_MS) })
    expect(result.current.state.phase).toBe('succeeded')

    act(() => { result.current.reset() })
    expect(result.current.state.phase).toBe('idle')
  })

  it('transitions to failed when execute throws', async () => {
    const client = makeClient({ execute: vi.fn().mockRejectedValue(new Error('net error')) })
    const { result } = renderHook(() => useExecution(client, 'ws', POLL_MS))

    await act(async () => {
      result.current.run('doc-approval.analyze', { document: 'text' })
      await Promise.resolve()
    })

    expect(result.current.state.phase).toBe('failed')
    expect((result.current.state as { phase: 'failed'; error: string }).error).toContain('net error')
  })

  it('transitions to failed when poll returns failed status', async () => {
    const client = makeClient({
      pollExecution: vi.fn().mockResolvedValue({ execution_id: 'exec-1', status: 'failed', error: 'boom' } as ExecutionResult),
    })
    const { result } = renderHook(() => useExecution(client, 'ws', POLL_MS))

    act(() => { result.current.run('doc-approval.analyze', { document: 'text' }) })
    await act(async () => { await Promise.resolve() })
    await act(async () => { await vi.advanceTimersByTimeAsync(POLL_MS) })

    expect(result.current.state.phase).toBe('failed')
    expect((result.current.state as { phase: 'failed'; error: string }).error).toBe('boom')
  })
})
