# Spec 002: Capability Event UI Subscription

**Created**: 2026-08-11  
**Status**: Approved  
**Approved**: 2026-08-11 (session authorization — event parity + Loop workstream)  
**Decision log**: [`../../decision-log.md`](../../decision-log.md) (2026-08-11)

## Purpose

Require every primary App-References client to subscribe to capability-scoped embedder events (`capability_invoked`, `capability_result`) and update UI based on capability execution evidence — without computing capability business outcomes in the UI.

## Upstream dependencies

- Spec [001](../001-ui-event-state-conformance/spec.md) (presentation-state mapper)
- Embedder API `embedder-api/1.0.0` (`capability_invoked`, `capability_result`)
- App manifest `state_machine` + `list_context_fields` conventions ([`../../app-manifest-schema.md`](../../app-manifest-schema.md))

## Architecture boundary

- UI may show capability id/version, invoke/result timing, and runtime-provided output paths listed in `list_context_fields`.
- UI MUST NOT infer titles, scores, recommendations, approvals, or other business fields from local heuristics.

## Functional requirements

- **FR-001**: After `submit`, hosts MUST retain ordered `capability_invoked` and `capability_result` events for the session (for UI progress and/or debug panels already present).
- **FR-002**: Multi-capability workflows MUST update UI capability progress from the event stream (e.g. which capability last invoked/completed), not from hard-coded step timers.
- **FR-003**: Final renderable product fields MUST be taken from runtime output carried on `capability_result` (or workflow terminal output fields), parsed by existing output parsers only.
- **FR-004**: Conformance fixtures MUST include at least one multi-capability ordered stream and assert UI/capability progress reflects invoke/result order.
- **FR-005**: Trace Explorer (web) MUST continue to expose capability phases via public Trace API / events without introducing private runtime imports; product shells MUST NOT depend on Trace Explorer internals.

## Acceptance scenarios

1. **Given** a two-capability fixture (`A` invoked→result, then `B` invoked→result), **When** the UI mapper consumes the stream, **Then** capability progress reflects A then B in order and ends `loaded` with B’s terminal output fields only from the fixture.
2. **Given** `capability_invoked` without a later result and no terminal error yet, **When** mapped, **Then** presentation remains `loading` and the active capability identity shown (if any) comes from the event payload.

## Validation

- Shared fixtures from Spec 001 extended with capability-progress assertions
- Per-app apply tickets prove parsers still reject non-runtime fields
