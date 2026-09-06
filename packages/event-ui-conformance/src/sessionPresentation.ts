import { activeCapabilityId, mapCapabilityProgress } from './capabilityProgress.ts'
import { mapPresentationState } from './mapPresentationState.ts'
import type {
  CapabilityProgressStep,
  EmbedderEventLike,
  PresentationState,
} from './types.ts'

/** Spec 001/002 fields derived from an ordered public embedder event stream. */
export type SessionPresentation = {
  presentationState: PresentationState
  presentationError: string | null
  capabilityProgress: CapabilityProgressStep[]
  activeCapabilityId: string | null
}

/** Minimal subscribe surface (compatible with public embedder hosts). */
export type SessionPresentationHost = {
  subscribe(listener: (event: EmbedderEventLike) => void): void
}

const IDLE_PRESENTATION: SessionPresentation = {
  presentationState: 'idle',
  presentationError: null,
  capabilityProgress: [],
  activeCapabilityId: null,
}

/** Map an ordered public embedder event stream to Spec 001/002 UI fields. */
export function mapSessionPresentation(
  events: readonly EmbedderEventLike[],
  options?: { fallbackError?: string | null },
): SessionPresentation {
  if (events.length === 0 && !options?.fallbackError) {
    return IDLE_PRESENTATION
  }
  const snap = mapPresentationState(events)
  const fallback = options?.fallbackError ?? null
  const presentationState: PresentationState =
    fallback && snap.state === 'idle' ? 'error' : snap.state
  return {
    presentationState,
    presentationError:
      snap.errorMessage ?? (fallback && snap.state === 'idle' ? fallback : null),
    capabilityProgress: mapCapabilityProgress(events),
    activeCapabilityId: activeCapabilityId(events),
  }
}

/**
 * Subscribe to a public embedder event stream and invoke `onChange` after each
 * event (including an initial empty → `idle` snapshot). Hosts typically have no
 * unsubscribe; drop the host when tearing down. Prefer a fresh subscribe per run
 * so prior sessions are not mixed into the mapped snapshot.
 */
export function observeSessionPresentation(
  host: SessionPresentationHost,
  onChange: (presentation: SessionPresentation) => void,
): void {
  const collected: EmbedderEventLike[] = []
  host.subscribe((event) => {
    collected.push(event)
    onChange(mapSessionPresentation(collected))
  })
  onChange(mapSessionPresentation(collected))
}
