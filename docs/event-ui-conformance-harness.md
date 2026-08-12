# Event UI conformance harness

Shared regression contract for mapping public Traverse embedder events to UI
presentation state (Specs
[`001`](specs/001-ui-event-state-conformance/spec.md) /
[`002`](specs/002-capability-event-ui-subscription/spec.md), ADR
[`0001`](adr/0001-event-fixture-harness-first.md)).

## Fixtures (language-agnostic)

Path: [`fixtures/event-ui-conformance/`](../fixtures/event-ui-conformance/)

| Case | Expected state |
|---|---|
| `happy-path.json` | `loaded` |
| `error-path.json` | `error` |
| `blocked-path.json` | `blocked` |
| `ended-path.json` | `ended` |
| `multi-capability.json` | `loaded` (+ ordered capability progress) |
| `replay-late-subscriber.json` | `loaded` (prefix replay ≡ full map) |

Catalog index: `fixtures/event-ui-conformance/catalog.json`.

Fixtures are static JSON — no network calls.

## TypeScript package

Workspace: `packages/event-ui-conformance` (`event-ui-conformance`).

```ts
import {
  loadFixtureCase,
  mapCapabilityProgress,
  mapPresentationState,
} from 'event-ui-conformance'

const fixture = loadFixtureCase('happy-path.json')
const ui = mapPresentationState(fixture.events)
// ui.state === 'loaded'; ui.output from capability_result only

const progress = mapCapabilityProgress(fixture.events)
```

Primary apps should import these helpers (or re-run the same fixtures with a
platform-native mapper) rather than inventing per-app event→state tables.

## Architecture boundary

- Subscribe / consume only public embedder envelopes (`state_changed`,
  `capability_invoked`, `capability_result`, `error`).
- Do **not** emit synthetic embedder events from production app code.
- Do **not** invent business fields in the UI; render runtime-provided `output`.
