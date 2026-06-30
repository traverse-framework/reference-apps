import { useState, useCallback, useRef } from 'react'
import {
  type TraverseClient,
  type ExecutionResult,
  type TraceEvent,
} from '../client/traverseClient'

export type ExecutionState =
  | { phase: 'idle' }
  | { phase: 'loading' }
  | { phase: 'polling'; executionId: string }
  | { phase: 'succeeded'; result: ExecutionResult; trace: TraceEvent[] }
  | { phase: 'failed'; error: string }

const POLL_TERMINAL: readonly string[] = ['succeeded', 'failed']

async function resolveTrace(
  client: TraverseClient,
  workspaceId: string,
  executionId: string | undefined,
): Promise<TraceEvent[]> {
  if (!executionId) return []
  return client.fetchTrace(workspaceId, executionId).catch(() => [])
}

export function useExecution(client: TraverseClient, workspaceId: string, pollIntervalMs = 1000) {
  const [state, setState] = useState<ExecutionState>({ phase: 'idle' })
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const stopPolling = useCallback(() => {
    if (pollRef.current !== null) {
      clearInterval(pollRef.current)
      pollRef.current = null
    }
  }, [])

  const run = useCallback(
    async (capabilityId: string, input: unknown) => {
      stopPolling()
      setState({ phase: 'loading' })

      try {
        const response = await client.execute(workspaceId, capabilityId, input)

        if (response.result?.status === 'succeeded') {
          const trace = await resolveTrace(client, workspaceId, response.result.execution_id)
          setState({ phase: 'succeeded', result: response.result, trace })
          return
        }

        const executionId = response.executionId
        if (!executionId) {
          setState({ phase: 'failed', error: 'execute response missing execution_id' })
          return
        }

        setState({ phase: 'polling', executionId })

        pollRef.current = setInterval(async () => {
          try {
            const result = await client.pollExecution(workspaceId, executionId)
            if (POLL_TERMINAL.includes(result.status)) {
              stopPolling()
              const trace = await resolveTrace(client, workspaceId, executionId)
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
      } catch (e) {
        setState({ phase: 'failed', error: String(e) })
      }
    },
    [client, workspaceId, stopPolling, pollIntervalMs],
  )

  return { state, run }
}
