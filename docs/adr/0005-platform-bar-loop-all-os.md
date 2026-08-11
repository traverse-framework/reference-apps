# ADR-0005: Loop All-OS Bar; Meeting-Notes Natives Follow-Up

- Status: Accepted
- Date: 2026-08-11
- Governing specs: `001-ui-event-state-conformance`, `003-loop-wf1-reference-app`

## Context

`traverse-starter` and `doc-approval` ship seven OS targets. `meeting-notes` today is web + Linux GTK + CLI. Trace Explorer is web-only by design (debugger). Full parity for Loop must not wait on meeting-notes ports, but the meeting-notes gap must not be forgotten.

## Decision

1. Phase 1 event-contract work updates every **existing** primary client platform.
2. Loop ships all seven OS targets (same bar as starter/doc-approval).
3. Completing meeting-notes iOS/macOS/Android/Windows is a tracked **Future** follow-up ticket, not part of Phase 1.
4. Trace Explorer remains web-only.

## Consequences

- Loop becomes a gold-standard product ref.
- meeting-notes matrix stays incomplete until the follow-up ships — explicitly tracked.
- Phase 1 stays bounded to subscription/conformance on platforms that already exist.

## Alternatives considered

- Port meeting-notes to all OS inside this workstream — deferred; too large before Loop.
- Loop matches meeting-notes (web/Linux/CLI only) — rejected; creates another incomplete product ref.
