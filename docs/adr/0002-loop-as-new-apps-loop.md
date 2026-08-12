# ADR-0002: Loop Lives in `apps/loop/`

- Status: Accepted
- Date: 2026-08-11
- Governing spec: `003-loop-wf1-reference-app`

## Context

Loop is positioned as a follow-through product, adjacent to but distinct from meeting-notes. Extending meeting-notes would blur the reference-app story.

## Decision

Create a new `apps/loop/` multi-platform reference app for WF1. Do not fold Loop into `meeting-notes`.

## Consequences

- More scaffolding than extending meeting-notes.
- Clear README / design-language product row for Loop.
- meeting-notes remains notes/transcript extraction; Loop owns follow-through WF1+.

## Alternatives considered

- Extend meeting-notes — rejected; muddies product identity.
- Web-only Loop shell — rejected; violates full ref-app parity bar.
