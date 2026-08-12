# Spec 004: Demo Upgrade-or-Retire Policy

**Created**: 2026-08-11  
**Status**: Approved  
**Approved**: 2026-08-11 (session authorization — event parity + Loop workstream)  
**Decision log**: [`../../decision-log.md`](../../decision-log.md) (2026-08-11)

## Purpose

Ensure App-References does not retain stale sample apps after the event-parity workstream. Every non-primary app under `apps/` is either upgraded to Specs 001/002 or retired with docs/CI scrubbed.

## Primary apps (not demos)

- `traverse-starter`
- `meeting-notes`
- `doc-approval`
- `trace-explorer` (debugger; web-only by design)

## Demo / kit inventory (initial)

At minimum the inventory ticket MUST classify:

- `apps/react-demo`
- `apps/browser-consumer`
- `apps/android-demo`
- `apps/macos-demo`
- `apps/youaskm3-starter-kit`

Additional `apps/*` entries that are not primaries MUST be listed in the same inventory PR.

## Functional requirements

- **FR-001**: Produce a written inventory table: path → `upgrade` | `retire` | `already-primary` with one-line rationale.
- **FR-002**: `upgrade` demos MUST meet Specs 001/002 on the platforms they claim to support, or lose those claims in README.
- **FR-003**: `retire` demos MUST be removed in a dedicated Project 2 ticket/PR that also drops CI jobs/workflows and updates README, design-language, getting-started, and any deep links.
- **FR-004**: README MUST include a short **Retired demos** note listing what was removed and when (PR/date).
- **FR-005**: Do not leave deprecated demos in `apps/` “for later.”

## Non-goals

- Treating expedition demos as production reference patterns after this policy ships
- Archiving into a long-lived `archive/` junk drawer (rejected by ADR-0004)

## Validation

- Inventory merged before retire/upgrade implementation tickets move to `Ready`
- Each retire PR greps clean for the removed path in docs and `.github/workflows`
