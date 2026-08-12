# Event UI conformance fixtures

Language-agnostic embedder event streams for Specs
[`001-ui-event-state-conformance`](../../docs/specs/001-ui-event-state-conformance/spec.md) and
[`002-capability-event-ui-subscription`](../../docs/specs/002-capability-event-ui-subscription/spec.md).

| Case | File | Expected presentation state |
|---|---|---|
| Happy path | `happy-path.json` | `loaded` |
| Error path | `error-path.json` | `error` |
| Blocked path | `blocked-path.json` | `blocked` |
| Ended path | `ended-path.json` | `ended` |
| Multi-capability | `multi-capability.json` | `loaded` |
| Replay / late subscriber | `replay-late-subscriber.json` | `loaded` |

Index: [`catalog.json`](./catalog.json).

TypeScript mappers and Vitest consumers live in
[`packages/event-ui-conformance`](../../packages/event-ui-conformance/).
See [`docs/event-ui-conformance-harness.md`](../../docs/event-ui-conformance-harness.md).
