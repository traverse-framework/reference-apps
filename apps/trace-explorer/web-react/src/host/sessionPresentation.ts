import type { EmbedderEventLike, SessionPresentation } from 'event-ui-conformance'
import {
  mapSessionPresentation as mapSessionPresentationFromPackage,
  observeSessionPresentation as observeSessionPresentationFromPackage,
} from 'event-ui-conformance'
import type { EmbedderEvent, TraverseEmbedderApi } from 'traverse-embedder-web'

export type { SessionPresentation }

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

/** Map an ordered public embedder event stream to Spec 001/002 UI fields. */
export function mapSessionPresentation(
  events: readonly EmbedderEvent[],
): SessionPresentation {
  return mapSessionPresentationFromPackage(toEventLikes(events))
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
