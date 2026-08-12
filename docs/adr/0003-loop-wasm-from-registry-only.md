# ADR-0003: Loop WASM Only From Traverse Registry

- Status: Accepted
- Date: 2026-08-11
- Governing spec: `003-loop-wf1-reference-app`

## Context

The Loop capability package v2 zip contains contracts and product/workflow docs only — no WASM binaries. App-References is UI-only.

## Decision

Loop clients consume digest-pinned agents/workflows published to the Traverse registry. App-References does not implement Loop capability WASM. Recorded fixtures are allowed only in unit tests, never as the primary demo path.

## Consequences

- `loop-wf1-multi-os` remains `Blocked` until registry digests exist (`loop-wf1-registry-deps`).
- Matches prior `consume-product-wasm-agents` pattern.
- UI work can scaffold hosts/tests against fixtures while blocked on publish.

## Alternatives considered

- Implement WASM in-repo — rejected; crosses architecture boundary.
- Fixture-driven primary demo — rejected; not a true embedded ref app.
