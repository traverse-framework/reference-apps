# App-References Specifications

Governing specs for App-References UI reference apps. These are **UI-layer** contracts; business logic and WASM live in Traverse / the registry.

## Status values

| Status | Meaning |
|---|---|
| `Draft` | Written but not approved |
| `Approved` | Approved for implementation (tickets may be `Ready` when unblocked) |
| `Superseded` | Replaced by a later spec |

## Index

| ID | Title | Status |
|---|---|---|
| [001](001-ui-event-state-conformance/spec.md) | UI event → presentation-state conformance | Approved |
| [002](002-capability-event-ui-subscription/spec.md) | Capability event UI subscription | Approved |
| [003](003-loop-wf1-reference-app/spec.md) | Loop WF1 multi-OS reference app | Approved |
| [004](004-demo-upgrade-or-retire/spec.md) | Demo upgrade-or-retire policy | Approved |

Upstream Traverse specs referenced by these docs include at least: `057-embeddable-runtime-host`, `010-runtime-state-machine`, `044-application-bundle-manifest`, and related embedder event envelope (`embedder-api/1.0.0`).

Decision records for this workstream: [`../decision-log.md`](../decision-log.md) (2026-08-11).
