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
import type { EmbedderEvent, TraverseEmbedderApi } from 'traverse-embedder-web'

export type SessionPresentation = {
  presentationState: PresentationState
  presentationError: string | null
  capabilityProgress: CapabilityProgressStep[]
  activeCapabilityId: string | null
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
): SessionPresentation {
  const likes = toEventLikes(events)
  const snap = mapPresentationState(likes)
  return {
    presentationState: snap.state,
    presentationError: snap.errorMessage,
    capabilityProgress: mapCapabilityProgress(likes),
    activeCapabilityId: activeCapabilityId(likes),
  }
}

/**
 * Subscribe to the public embedder event stream and invoke `onChange` after each
 * event (including replay). The embedder API has no unsubscribe; drop the host
 * when tearing down.
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
