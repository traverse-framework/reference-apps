# Spec 001: UI Event → Presentation-State Conformance

**Created**: 2026-08-11  
**Status**: Approved  
**Approved**: 2026-08-11 (session authorization — event parity + Loop workstream)  
**Decision log**: [`../../decision-log.md`](../../decision-log.md) (2026-08-11)

## Purpose

Define the governed mapping from public Traverse embedder events to UI presentation states for every App-References primary client, and require automated fixture-based conformance so registry/runtime churn cannot silently break loading / loaded / blocked / ended / error UX.

## Upstream dependencies

- Traverse embedder API `embedder-api/1.0.0` event envelope (`event_type`: `state_changed` | `capability_invoked` | `capability_result` | `error`)
- Traverse spec `010-runtime-state-machine` (runtime lifecycle states inside `state_changed` payloads)
- Traverse spec `057-embeddable-runtime-host` (subscribe/replay semantics)
- App-References constitution: UI is a rendering layer; runtime-driven UI state

## Architecture boundary

- **In scope (this repo):** subscribe via public platform embedders; map events → presentation state; render; unit-test with embedder test doubles / fixtures.
- **Out of scope:** inventing runtime states, emitting fake runtime events from app code, computing business fields in the UI, importing private Traverse internals.

## Presentation states (canonical UI vocabulary)

Every primary product shell MUST be able to present these mutually exclusive session presentation states (names may be styled in UI copy, but code and tests MUST use these identifiers):

| Presentation state | Meaning |
|---|---|
| `idle` | No active session / ready for input |
| `loading` | Session accepted; execution in progress (non-terminal) |
| `loaded` | Terminal success with structured output available to render |
| `blocked` | Execution waiting on a human/runtime-gated step exposed by events (when present) |
| `ended` | Terminal completion without treating as error (e.g. cancelled/closed when runtime emits it) |
| `error` | Terminal failure |

Apps MAY show richer intermediate labels derived only from runtime `state_changed` payloads, but conformance tests assert the six presentation states above.

## Functional requirements

- **FR-001**: Hosts MUST subscribe through the public embedder `subscribe` API (or platform equivalent) and MUST replay-safe consume ordered events.
- **FR-002**: A deterministic pure mapper (per language family as needed) MUST map an ordered event stream to exactly one current presentation state.
- **FR-003**: `error` embedder events MUST map to presentation `error` with a user-visible message sourced from event payload fields (no invented business diagnosis).
- **FR-004**: `capability_result` (success path) MUST map to `loaded` when output is present; absence of output with terminal success semantics maps to `ended` when the runtime indicates completion without renderable product fields.
- **FR-005**: Non-terminal `state_changed` / `capability_invoked` sequences after submit acceptance MUST map to `loading` until a terminal event.
- **FR-006**: When runtime payloads indicate a blocked/waiting-for-human condition, the mapper MUST surface `blocked` (not invent local business rules to decide blocking).
- **FR-007**: Shared fixture catalogs MUST cover at least: happy path, error path, blocked path, empty/ended path, and late-subscriber replay equivalence.
- **FR-008**: Primary apps (`traverse-starter`, `meeting-notes`, `doc-approval`, `trace-explorer` where applicable) MUST run fixture conformance on every platform already covered by that app’s CI.

## Non-goals

- Replacing Trace Explorer’s debugger UX with product-shell chrome
- Defining new embedder `event_type` values
- Requiring HTTP sidecar for production UX

## Acceptance scenarios

1. **Given** a fixture stream ending in `capability_result` with output, **When** the mapper runs, **Then** presentation state is `loaded` and UI fields come only from parsed runtime output.
2. **Given** a fixture stream ending in `error`, **When** the mapper runs, **Then** presentation state is `error` and no fabricated success fields appear.
3. **Given** a mid-stream `capability_invoked` / `state_changed` sequence with no terminal event yet, **When** the mapper runs, **Then** presentation state is `loading`.
4. **Given** two subscribers attaching at different times to the same recorded stream (replay), **When** both map, **Then** they reach the same presentation state.

## Validation

- Unit tests over shared fixtures (web Vitest and platform-equivalent where CI exists)
- No app code emits synthetic embedder events outside tests
- `npm run test` / platform unit targets listed on apply tickets pass
