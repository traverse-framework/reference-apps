# ADR-0001: Shared Event-Fixture Harness Before Per-App Work

- Status: Accepted
- Date: 2026-08-11
- Governing specs: `001-ui-event-state-conformance`, `002-capability-event-ui-subscription`

## Context

Traverse embedder events and the registry changed. Four primary App-References products need the same event→UI presentation mapping. Implementing that mapping independently per app risks four divergent contracts.

## Decision

Land a foundational shared event-fixture harness and pure mapping helpers/docs first. Only then apply the harness to each primary app via separate tickets.

## Consequences

- Per-app parity tickets stay `Blocked` on `event-ui-conformance-harness` until it merges.
- One fixture catalog becomes the regression guard for registry churn.
- Language-specific adapters may exist (TS / Swift / Kotlin / Rust), but fixtures and presentation-state vocabulary stay shared.

## Alternatives considered

- Per-app family tickets only — rejected; duplicates the contract.
- Per-platform tickets across all apps — rejected; leaves products half-updated.
