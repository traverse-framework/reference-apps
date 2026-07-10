import { useState, useCallback, useRef } from 'react'
import { type TraverseClient, type ExecutionResult, type TraceEvent } from '../client/traverseClient'

export type ExecutionState =
  | { phase: 'idle' }
  | { phase: 'loading' }
  | { phase: 'polling'; executionId: string }
  | { phase: 'succeeded'; result: ExecutionResult; trace: TraceEvent[] }
  | { phase: 'failed'; error: string }

const POLL_TERMINAL: readonly string[] = ['succeeded', 'failed']

export function useExecution(client: TraverseClient, workspaceId: string, pollIntervalMs = 1000) {
  const [state, setState] = useState<ExecutionState>({ phase: 'idle' })
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const stopPolling = useCallback(() => {
    if (pollRef.current !== null) {
      clearInterval(pollRef.current)
      pollRef.current = null
    }
  }, [])

  const reset = useCallback(() => {
    stopPolling()
    setState({ phase: 'idle' })
  }, [stopPolling])

  const run = useCallback(
    async (capability: string, input: unknown) => {
      stopPolling()
      setState({ phase: 'loading' })

      let executionId: string
      try {
        executionId = await client.execute(workspaceId, capability, input)
      } catch (e) {
        setState({ phase: 'failed', error: String(e) })
        return
      }

      setState({ phase: 'polling', executionId })

      pollRef.current = setInterval(async () => {
        try {
          const result = await client.pollExecution(workspaceId, executionId)
          if (POLL_TERMINAL.includes(result.status)) {
            stopPolling()
            const trace = await client.fetchTrace(workspaceId, executionId).catch(() => [])
            if (result.status === 'succeeded') {
              setState({ phase: 'succeeded', result, trace })
            } else {
              setState({ phase: 'failed', error: result.error ?? 'execution failed' })
            }
          }
        } catch (e) {
          stopPolling()
          setState({ phase: 'failed', error: String(e) })
        }
      }, pollIntervalMs)
    },
    [client, workspaceId, stopPolling, pollIntervalMs],
  )

  return { state, run, reset }
}
