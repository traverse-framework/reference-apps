# Traverse Browser Consumer Package

Browser-targeted consumer façade for downstream apps such as `youaskm3`.

Canonical home: **`traverse-framework/reference-apps`** (`apps/browser-consumer/`).

It reuses the approved live browser adapter client from [`apps/react-demo/`](../react-demo/) and exposes a browser-safe subscription flow. Runtime ordering, trace visibility, and terminal outcomes come from Traverse public surfaces — not private app logic.

## Quick Start

```bash
node -e "const client = require('./apps/browser-consumer'); console.log(client.APPROVED_BROWSER_CONSUMER_SESSION.title)"
```

## Validation

Offline façade load is covered by `bash scripts/ci/youaskm3_starter_kit_smoke.sh`.

Live adapter path (requires `TRAVERSE_REPO`):

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/browser_consumer_package_smoke.sh
```
