/** Canonical UI presentation states (Spec 001). */
export type PresentationState =
  | 'idle'
  | 'loading'
  | 'loaded'
  | 'blocked'
  | 'ended'
  | 'error'

/** JSON wire value (matches public embedder JsonValue). */
export type JsonValue =
  | string
  | number
  | boolean
  | null
  | JsonValue[]
  | { [key: string]: JsonValue }

/**
 * Public embedder event envelope fields required by the harness.
 * Compatible with `traverse-embedder-web` `EmbedderEvent`.
 */
export interface EmbedderEventLike {
  readonly event_type: 'state_changed' | 'capability_invoked' | 'capability_result' | 'error'
  readonly sequence: number
  readonly session_id?: string | null
  readonly data: JsonValue
}

export interface PresentationSnapshot {
  readonly state: PresentationState
  readonly errorMessage: string | null
  /** Last `capability_result.data.output` when present; never invented. */
  readonly output: JsonValue | null
}

export type CapabilityPhase = 'invoked' | 'result'

export interface CapabilityProgressStep {
  readonly capabilityId: string
  readonly phase: CapabilityPhase
  readonly sequence: number
  readonly status: string | null
  readonly output: JsonValue | null
}

export interface FixtureCase {
  readonly id: string
  readonly description: string
  readonly expected_presentation_state: PresentationState
  readonly expected_error_message?: string | null
  readonly expected_capability_order?: readonly {
    readonly capability_id: string
    readonly phase: CapabilityPhase
  }[]
  readonly events: readonly EmbedderEventLike[]
}

export interface FixtureCatalogEntry {
  readonly id: string
  readonly file: string
  readonly expected_presentation_state: PresentationState
  readonly notes?: string
}

export interface FixtureCatalog {
  readonly schema_version: string
  readonly description: string
  readonly cases: readonly FixtureCatalogEntry[]
}
