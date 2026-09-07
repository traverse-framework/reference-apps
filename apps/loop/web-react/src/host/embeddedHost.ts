import type { EmbedderEventLike, PresentationState, SessionPresentation } from 'event-ui-conformance'
import {
  mapSessionPresentation,
  observeSessionPresentation as observeSessionPresentationFromPackage,
} from 'event-ui-conformance'
import type {
  EmbedderEvent,
  JsonValue,
  TraverseEmbedderApi,
} from 'traverse-embedder-web'
import { BundleEmbedder, EmbedderTestDouble, FetchBundleLoader } from 'traverse-embedder-web'
import { parseLoopOutput, type LoopOutput } from '../client/traverseOutput'

export const RUNTIME_MODE_EMBEDDED = 'Embedded'
export const DEFAULT_WORKFLOW_ID = 'loop.wf1'
export const DEFAULT_WORKSPACE = 'local-default'
export const DEFAULT_APP_ID = 'loop'
export const DEFAULT_MANIFEST_PATH = '/bundles/loop/app.manifest.json'

export type RuntimeStatus = 'starting' | 'ready' | 'unavailable'

export interface TraceEvent {
  event_type: string
  timestamp: string
  data?: unknown
}

export interface HostRunResult {
  sessionId: string
  output: LoopOutput | null
  rawOutput: unknown
  events: TraceEvent[]
  error: string | null
  /** Spec 001 presentation state from the public embedder event stream. */
  presentationState: PresentationState
  /** Spec 001 error text from event payloads (never invented). */
  presentationError: string | null
  /** Spec 002 ordered capability invoke/result progress. */
  capabilityProgress: SessionPresentation['capabilityProgress']
  /** Spec 002 active capability id when an invoke is still open. */
  activeCapabilityId: string | null
}

export type { TraverseEmbedderApi, EmbedderEvent, PresentationState, SessionPresentation }
export type { CapabilityProgressStep } from 'event-ui-conformance'

export function createTestEmbedder(output: LoopOutput): TraverseEmbedderApi {
  return new EmbedderTestDouble({
    workspaceId: DEFAULT_WORKSPACE,
    appId: DEFAULT_APP_ID,
    appVersion: '1.0.0',
    platform: 'web',
  }).withTargetOutput(DEFAULT_WORKFLOW_ID, output as unknown as JsonValue)
}

/** BundleEmbedder.init; returns null when the local bundle cannot be loaded. */
export async function initProductionEmbedder(
  manifestPath = import.meta.env.VITE_LOOP_MANIFEST ?? DEFAULT_MANIFEST_PATH,
): Promise<TraverseEmbedderApi | null> {
  try {
    return await BundleEmbedder.init({
      manifestPath,
      loader: new FetchBundleLoader(),
      workspaceId: DEFAULT_WORKSPACE,
      platform: 'web',
    })
  } catch {
    return null
  }
}

function errorMessageFromData(data: JsonValue): string | null {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return null
  const err = (data as Record<string, JsonValue>).error
  if (typeof err === 'string') return err
  if (err && typeof err === 'object' && !Array.isArray(err)) {
    const message = (err as Record<string, JsonValue>).message
    if (typeof message === 'string') return message
  }
  return null
}

function toEventLike(event: EmbedderEvent): EmbedderEventLike {
  return {
    event_type: event.event_type,
    sequence: event.sequence,
    session_id: event.session_id,
    data: event.data,
  }
}

function toEventLikes(events: readonly EmbedderEvent[]): EmbedderEventLike[] {
  return events.map(toEventLike)
}

/** Map public embedder events to Spec 001/002 UI fields (shared package). */
export function mapEmbedderSessionPresentation(
  events: readonly EmbedderEvent[],
  options?: { fallbackError?: string | null },
): SessionPresentation {
  return mapSessionPresentation(toEventLikes(events), options)
}

/**
 * Subscribe via the public embedder API and map each event with the shared
 * Spec 001/002 helpers. Prefer a fresh subscribe per run.
 */
export function observeSessionPresentation(
  host: TraverseEmbedderApi,
  onChange: (presentation: SessionPresentation) => void,
): void {
  observeSessionPresentationFromPackage(
    {
      subscribe(listener) {
        host.subscribe((event) => {
          listener(toEventLike(event))
        })
      },
    },
    onChange,
  )
}

function withPresentation(
  base: Omit<
    HostRunResult,
    'presentationState' | 'presentationError' | 'capabilityProgress' | 'activeCapabilityId'
  >,
  collected: readonly EmbedderEvent[],
): HostRunResult {
  return {
    ...base,
    ...mapEmbedderSessionPresentation(collected, { fallbackError: base.error }),
  }
}

/** Submit `{ transcript }` to `loop.wf1` and collect terminal output. */
export function submitTranscript(
  embedder: TraverseEmbedderApi,
  transcript: string,
  onPresentation?: (presentation: SessionPresentation) => void,
): HostRunResult {
  const collected: EmbedderEvent[] = []
  embedder.subscribe((event) => {
    collected.push(event)
    onPresentation?.(mapEmbedderSessionPresentation(collected))
  })

  const outcome = embedder.submit(DEFAULT_WORKFLOW_ID, { transcript })
  if (outcome.status === 'rejected') {
    const rejected = withPresentation(
      {
        sessionId: outcome.sessionId ?? 'sess-unknown',
        output: null,
        rawOutput: null,
        events: [],
        error: outcome.error
          ? `${outcome.error.code}: ${outcome.error.message}`
          : 'submit rejected',
      },
      [],
    )
    onPresentation?.({
      presentationState: rejected.presentationState,
      presentationError: rejected.presentationError,
      capabilityProgress: rejected.capabilityProgress,
      activeCapabilityId: rejected.activeCapabilityId,
    })
    return rejected
  }

  const sessionId = outcome.sessionId ?? 'sess-unknown'
  const events: TraceEvent[] = collected.map((event) => ({
    event_type: event.event_type,
    timestamp: String(event.sequence),
    data: event.data,
  }))

  for (const event of collected) {
    if (event.session_id && event.session_id !== sessionId) continue
    if (event.event_type === 'error') {
      return withPresentation(
        {
          sessionId,
          output: null,
          rawOutput: null,
          events,
          error: errorMessageFromData(event.data) ?? 'execution failed',
        },
        collected,
      )
    }
    if (event.event_type === 'capability_result') {
      const data =
        event.data && typeof event.data === 'object' && !Array.isArray(event.data)
          ? (event.data as Record<string, JsonValue>)
          : null
      const rawOutput = data?.output ?? null
      return withPresentation(
        {
          sessionId,
          output: parseLoopOutput(rawOutput),
          rawOutput,
          events,
          error: null,
        },
        collected,
      )
    }
  }

  return withPresentation(
    {
      sessionId,
      output: null,
      rawOutput: null,
      events,
      error: 'embedder emitted no capability_result',
    },
    collected,
  )
}
