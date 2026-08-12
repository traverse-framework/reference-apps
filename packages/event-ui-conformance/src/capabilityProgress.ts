import { asString, isRecord } from './json.ts'
import type { CapabilityProgressStep, EmbedderEventLike, JsonValue } from './types.ts'

function capabilityIdFromData(data: JsonValue): string | null {
  if (!isRecord(data)) return null
  return asString(data.capability_id)
}

/**
 * Ordered capability progress from `capability_invoked` / `capability_result`.
 * Identity and status/output come only from event payloads.
 */
export function mapCapabilityProgress(
  events: readonly EmbedderEventLike[],
): CapabilityProgressStep[] {
  const steps: CapabilityProgressStep[] = []

  for (const event of events) {
    if (event.event_type !== 'capability_invoked' && event.event_type !== 'capability_result') {
      continue
    }
    const capabilityId = capabilityIdFromData(event.data)
    if (!capabilityId) continue

    if (event.event_type === 'capability_invoked') {
      steps.push({
        capabilityId,
        phase: 'invoked',
        sequence: event.sequence,
        status: null,
        output: null,
      })
      continue
    }

    const status = isRecord(event.data) ? asString(event.data.status) : null
    const output = isRecord(event.data) && 'output' in event.data ? event.data.output : null
    steps.push({
      capabilityId,
      phase: 'result',
      sequence: event.sequence,
      status,
      output: output ?? null,
    })
  }

  return steps
}

/** Active capability for UI chrome: last invoked without a later result for that id. */
export function activeCapabilityId(events: readonly EmbedderEventLike[]): string | null {
  const progress = mapCapabilityProgress(events)
  const open = new Map<string, number>()

  for (const step of progress) {
    if (step.phase === 'invoked') {
      open.set(step.capabilityId, (open.get(step.capabilityId) ?? 0) + 1)
    } else {
      const count = open.get(step.capabilityId) ?? 0
      if (count <= 1) open.delete(step.capabilityId)
      else open.set(step.capabilityId, count - 1)
    }
  }

  for (let i = progress.length - 1; i >= 0; i -= 1) {
    const step = progress[i]
    if (step.phase === 'invoked' && open.has(step.capabilityId)) {
      return step.capabilityId
    }
  }
  return null
}
