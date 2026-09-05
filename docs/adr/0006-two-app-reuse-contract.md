# ADR-0006: Shared `meeting-notes.process` 1.3.2 for meeting-notes and Loop

- Status: Accepted
- Date: 2026-09-05
- Governing ticket: `two-app-reuse-contract` (#281)
- Upstream: Traverse #1168

## Context

Traverse #1168 requires proof that a published capability is a reusable platform unit: two independently scoped applications consume the **same** immutable release through supported registry/host paths, without copying business logic. Today meeting-notes and Loop both name `meeting-notes.process` but can resolve different artifacts (`^1.0.0` → 1.0.0 digest `sha256:5647c39a…` vs Loop’s 1.3.2 digest `sha256:ec192a0c…`).

## Decision

Pin **both** `meeting-notes` and `loop` to public `meeting-notes.process` **1.3.2** (`registry_ref.version_range` exactly `1.3.2`, artifact digest `sha256:ec192a0c2104b08bee76418c5c6d44358036568d655d8465e506858d1aaadbf2`). Full pin, host routes, and current drift: [`../two-app-reuse-contract.md`](../two-app-reuse-contract.md).

This ADR does not implement alignment or execution. `#282` applies the pin and produces evidence. `#283` covers upgrade/deprecation.

## Consequences

- Floating caret ranges are forbidden for this shared pin so the two apps cannot silently diverge.
- Meeting-notes must leave the 1.0.0 fixture digest; I/O schema stays compatible.
- App-References still does not author the WASM. Interim sync materialize from `$TRAVERSE_REPO` examples is not a second capability.
- Loop remains a separate `app_id` with WF1 composition; meeting-notes remains the standalone notes shell (ADR 0002).

## Alternatives considered

- Share `traverse-starter.process` — rejected; no second product workflow.
- Share `core.extract-action-items` — rejected; meeting-notes has no extract step.
- Leave `^` ranges and document “latest 1.x” — rejected; #1168 requires one immutable artifact.
