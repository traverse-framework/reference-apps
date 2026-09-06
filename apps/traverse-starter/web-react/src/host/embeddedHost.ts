import type {
  CapabilityProgressStep,
  EmbedderEventLike,
  PresentationState,
} from 'event-ui-conformance'
import {
  activeCapabilityId,
  mapCapabilityProgress,
  mapPresentationState,
} from 'event-ui-conformance'
import type {
  EmbedderEvent,
  JsonValue,
  TraverseEmbedderApi,
} from 'traverse-embedder-web'
import { BundleEmbedder, EmbedderTestDouble, FetchBundleLoader } from 'traverse-embedder-web'
import type { TraverseStarterOutput } from '../client/traverseOutput'
import { parseOutput } from '../client/traverseOutput'

export const RUNTIME_MODE_EMBEDDED = 'Embedded'
export const DEFAULT_WORKFLOW_ID = 'traverse-starter.pipeline'
export const DEFAULT_WORKSPACE = 'local-default'
export const DEFAULT_APP_ID = 'traverse-starter'
export const DEFAULT_MANIFEST_PATH = '/bundles/traverse-starter/app.manifest.json'

export type RuntimeStatus = 'starting' | 'ready' | 'unavailable'

export interface TraceEvent {
  event_type: string
  timestamp: string
  data?: unknown
}

export interface HostRunResult {
  sessionId: string
  output: TraverseStarterOutput | null
  rawOutput: unknown
  events: TraceEvent[]
  error: string | null
  /** Spec 001 presentation state from the public embedder event stream. */
  presentationState: PresentationState
  /** Spec 001 error text from event payloads (never invented). */
  presentationError: string | null
  /** Spec 002 ordered capability invoke/result progress. */
  capabilityProgress: CapabilityProgressStep[]
  /** Spec 002 active capability id when an invoke is still open. */
  activeCapabilityId: string | null
}

export type { TraverseEmbedderApi, EmbedderEvent, PresentationState, CapabilityProgressStep }

/** Spec 001/002 fields derived from an ordered public embedder event stream. */
export type SessionPresentation = {
  presentationState: PresentationState
  presentationError: string | null
  capabilityProgress: CapabilityProgressStep[]
  activeCapabilityId: string | null
}

const IDLE_PRESENTATION: SessionPresentation = {
  presentationState: 'idle',
  presentationError: null,
  capabilityProgress: [],
  activeCapabilityId: null,
}

/** Builds a deterministic test double for Vitest (spec 068 FR-006). */
export function createTestEmbedder(output: TraverseStarterOutput): TraverseEmbedderApi {
  return new EmbedderTestDouble({
    workspaceId: DEFAULT_WORKSPACE,
    appId: DEFAULT_APP_ID,
    appVersion: '1.1.0',
    platform: 'web',
  }).withTargetOutput(DEFAULT_WORKFLOW_ID, output as unknown as JsonValue)
}

/** Production init via FetchBundleLoader. Returns null when the bundle is unavailable. */
export async function initProductionEmbedder(
  manifestPath = import.meta.env.VITE_TRAVERSE_STARTER_MANIFEST ?? DEFAULT_MANIFEST_PATH,
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

function toEventLikes(events: readonly EmbedderEvent[]): EmbedderEventLike[] {
  return events.map((event) => ({
    event_type: event.event_type,
    sequence: event.sequence,
    session_id: event.session_id,
    data: event.data,
  }))
}

/** Map an ordered public embedder event stream to Spec 001/002 UI fields. */
export function mapSessionPresentation(
  events: readonly EmbedderEvent[],
  options?: { fallbackError?: string | null },
): SessionPresentation {
  if (events.length === 0 && !options?.fallbackError) {
    return IDLE_PRESENTATION
  }
  const likes = toEventLikes(events)
  const snap = mapPresentationState(likes)
  const fallback = options?.fallbackError ?? null
  const presentationState: PresentationState =
    fallback && snap.state === 'idle' ? 'error' : snap.state
  return {
    presentationState,
    presentationError: snap.errorMessage ?? (fallback && snap.state === 'idle' ? fallback : null),
    capabilityProgress: mapCapabilityProgress(likes),
    activeCapabilityId: activeCapabilityId(likes),
  }
}

/**
 * Subscribe to the public embedder event stream and invoke `onChange` after each
 * event (including an initial empty → `idle` snapshot). The embedder API has no
 * unsubscribe; drop the host when tearing down.
 */
export function observeSessionPresentation(
  host: TraverseEmbedderApi,
  onChange: (presentation: SessionPresentation) => void,
): void {
  const collected: EmbedderEvent[] = []
  host.subscribe((event) => {
    collected.push(event)
    onChange(mapSessionPresentation(collected))
  })
  onChange(mapSessionPresentation(collected))
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
    ...mapSessionPresentation(collected, { fallbackError: base.error }),
  }
}

/** Submit `{ note }` to `traverse-starter.pipeline` and collect terminal output. */
export function submitNote(
  embedder: TraverseEmbedderApi,
  note: string,
  onPresentation?: (presentation: SessionPresentation) => void,
): HostRunResult {
  const collected: EmbedderEvent[] = []
  embedder.subscribe((event) => {
    collected.push(event)
    onPresentation?.(mapSessionPresentation(collected))
  })

  const outcome = embedder.submit(DEFAULT_WORKFLOW_ID, { note })
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
          output: parseOutput(rawOutput),
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
