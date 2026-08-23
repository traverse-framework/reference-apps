# ADR-0003: Loop WASM Only From Traverse Registry

- Status: Accepted
- Date: 2026-08-11
- Governing spec: `003-loop-wf1-reference-app`

## Context

The Loop capability package v2 zip contains contracts and product/workflow docs only — no WASM binaries. App-References is UI-only.

## Decision

Loop clients consume digest-pinned agents/workflows published to the Traverse registry. App-References does not implement Loop capability WASM. Recorded fixtures are allowed only in unit tests, never as the primary demo path.

## Consequences

- Capability digests for WF1 are inventoried in `docs/loop-registry-deps.md` (ticket `loop-wf1-registry-deps`); `loop-wf1-multi-os` may proceed with in-app workflow composition over those `registry_ref`s.
- Matches prior `consume-product-wasm-agents` pattern.
- A first-party registry-hosted `workflows/loop/...` publish remains optional Future work.

## Alternatives considered

- Implement WASM in-repo — rejected; crosses architecture boundary.
- Fixture-driven primary demo — rejected; not a true embedded ref app.
