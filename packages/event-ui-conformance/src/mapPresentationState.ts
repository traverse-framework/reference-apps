import { asString, isRecord } from './json.ts'
import type { EmbedderEventLike, JsonValue, PresentationSnapshot, PresentationState } from './types.ts'

const BLOCKED_STATES = new Set([
  'blocked',
  'waiting',
  'waiting_for_human',
  'awaiting_human',
  'awaiting_input',
])

const ENDED_STATES = new Set(['cancelled', 'canceled', 'closed', 'ended'])

function errorMessageFromData(data: JsonValue): string | null {
  if (!isRecord(data)) return null
  const err = data.error
  if (typeof err === 'string') return err
  if (isRecord(err)) {
    const message = err.message
    if (typeof message === 'string') return message
  }
  return null
}

function runtimeStateToken(data: JsonValue): string | null {
  if (!isRecord(data)) return null
  return (
    asString(data.state) ??
    asString(data.status) ??
    asString(data.runtime_state) ??
    null
  )
}

function isBlockedPayload(data: JsonValue): boolean {
  if (!isRecord(data)) return false
  if (data.blocked === true || data.waiting_for_human === true) return true
  const token = runtimeStateToken(data)
  return token !== null && BLOCKED_STATES.has(token.toLowerCase())
}

function isEndedStatePayload(data: JsonValue): boolean {
  const token = runtimeStateToken(data)
  return token !== null && ENDED_STATES.has(token.toLowerCase())
}

function hasRenderableOutput(data: JsonValue): boolean {
  if (!isRecord(data)) return false
  if (!('output' in data)) return false
  const output = data.output
  if (output === null || output === undefined) return false
  if (typeof output === 'object' && !Array.isArray(output) && Object.keys(output).length === 0) {
    return false
  }
  return true
}

/**
 * Pure mapper: ordered public embedder events → one presentation snapshot.
 * Does not invent business fields; output is copied from capability_result only.
 */
export function mapPresentationState(
  events: readonly EmbedderEventLike[],
): PresentationSnapshot {
  if (events.length === 0) {
    return { state: 'idle', errorMessage: null, output: null }
  }

  let state: PresentationState = 'idle'
  let errorMessage: string | null = null
  let output: JsonValue | null = null

  for (const event of events) {
    switch (event.event_type) {
      case 'error': {
        state = 'error'
        errorMessage = errorMessageFromData(event.data) ?? 'execution failed'
        break
      }
      case 'capability_invoked': {
        if (state !== 'error') {
          state = 'loading'
        }
        break
      }
      case 'state_changed': {
        if (state === 'error') break
        if (isBlockedPayload(event.data)) {
          state = 'blocked'
        } else if (isEndedStatePayload(event.data)) {
          state = 'ended'
        } else if (state !== 'loaded' && state !== 'ended') {
          state = 'loading'
        }
        break
      }
      case 'capability_result': {
        if (state === 'error') break
        if (hasRenderableOutput(event.data) && isRecord(event.data)) {
          state = 'loaded'
          output = event.data.output ?? null
        } else {
          state = 'ended'
          output = null
        }
        break
      }
    }
  }

  return { state, errorMessage, output }
}
