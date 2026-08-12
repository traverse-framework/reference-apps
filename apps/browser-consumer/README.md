# Traverse Browser Consumer Package

Browser-targeted consumer façade for downstream apps such as `youaskm3`.

Canonical home: **`traverse-framework/reference-apps`** (`apps/browser-consumer/`).

It owns a copy of the approved live browser adapter client under
[`src/browser-adapter-client.js`](./src/browser-adapter-client.js) and exposes a
browser-safe subscription flow. Runtime ordering, trace visibility, and terminal
outcomes come from Traverse public surfaces — not private app logic and not from
other demo app trees.

## Specs 001 / 002

Session chrome uses Spec 001 presentation states
(`idle|loading|loaded|blocked|ended|error`) via `presentationState` on consumer
state (mapped from subscription lifecycle evidence). Capability/progress UI must
follow Spec 002: show invoke/result evidence from the stream — never invent
business fields locally.

See [`docs/event-ui-conformance-harness.md`](../../docs/event-ui-conformance-harness.md)
for the shared fixture contract used by primary shells.

## Quick Start

```bash
node -e "const client = require('./apps/browser-consumer'); console.log(client.APPROVED_BROWSER_CONSUMER_SESSION.title)"
```

## Validation

Offline façade load is covered by `bash scripts/ci/youaskm3_starter_kit_smoke.sh`.

Live adapter path (requires `TRAVERSE_REPO`; talks to `browser-adapter serve` directly):

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/browser_consumer_package_smoke.sh
```
