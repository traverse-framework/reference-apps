# Traverse Runtime Setup

This document covers **how to run the Traverse runtime for local development**. For the **production target** (embedded in-app host), see [`embedded-runtime-plan.md`](embedded-runtime-plan.md).

## Deployment Models

| Model | Status | Use when |
|---|---|---|
| **Embedded in-app host (Phase 3)** | Target — not yet in platform clients | Building/shipping reference apps to end users |
| **HTTP sidecar `traverse-cli serve` (Phase 1/2)** | Current dev path | Local development, CI smoke tests, trace-explorer |

End-user apps **must not** depend on a separately running sidecar. The sidecar exists so developers can iterate before the embeddable host SDK ships in Traverse.

## Pinned Version

| Phase | Minimum version | Adds |
|---|---|---|
| Phase 1 (HTTP integration) | **v0.3.0** | HTTP/JSON API, `/healthz`, execute, poll, trace |
| Phase 2 (CLI app registration) | **v0.5.0** | `traverse-cli app validate/register`, workspace state |
| Phase 3 (embedded host) | **TBD** | In-app WASM runtime host SDK per platform |

**Current release: v0.6.0** — recommended for Phase 1/2 dev sidecar.

Requirements: Rust 1.94+

## Dev Sidecar — Start the Runtime

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse
git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

The runtime writes a discovery file on startup:

```bash
cat .traverse/server.json
# {
#   "base_url": "http://127.0.0.1:8787",
#   "health_url": "http://127.0.0.1:8787/healthz",
#   "workspace_default": "local-default",
#   "auth_mode": "dev-loopback"
# }
```

## HTTP API Surface (dev sidecar only)

Governed by `033-http-json-api` (approved v1.1.0).

| Endpoint | Method | Purpose |
|---|---|---|
| `/healthz` | GET | Health check |
| `/v1/workspaces/{workspace_id}/execute` | POST | Execute a capability (Phase 1) |
| `/v1/workspaces/{workspace_id}/executions/{execution_id}` | GET | Poll execution status (Phase 1) |
| `/v1/workspaces/{workspace_id}/traces/{execution_id}` | GET | Fetch public trace |
| `/v1/workspaces/{workspace_id}/capabilities` | POST | Register a capability |
| `/v1/workspaces/{workspace_id}/apps/{app_id}/events` | GET | App state SSE stream (EventSource) |
| `/v1/workspaces/{workspace_id}/apps/{app_id}/commands` | POST | Dispatch command to app state machine |
| `/v1/workspaces/{workspace_id}/apps/{app_id}/sessions` | GET | List app state-machine sessions |

`traverse-starter` web-react uses **commands + SSE** (not execute/poll) as the reference client pattern.

Default workspace: `local-default`

Phase 3 embedded clients use the **public host SDK** instead of these HTTP endpoints for in-process execution.

## Discovery in App Code (Phase 1/2 — dev only)

```typescript
import fs from 'fs'

const server = JSON.parse(fs.readFileSync('.traverse/server.json', 'utf8'))
const baseUrl = server.base_url          // http://127.0.0.1:8787
const workspaceId = server.workspace_default  // local-default
```

In the browser (Vite env vars):

```typescript
const baseUrl = import.meta.env.VITE_TRAVERSE_BASE_URL ?? 'http://127.0.0.1:8787'
const workspaceId = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'
```

Phase 3 clients load bundled manifests from the app artifact and initialize an in-process workspace — no URL discovery.

## Validation

Phase 1/2: `bash scripts/ci/phase1_smoke.sh` (sidecar) and `bash scripts/ci/phase2_smoke.sh` (CLI registration).

Phase 3: `bash scripts/ci/embedded_smoke.sh` — sync/link real bundles, init the public embedder, submit `traverse-starter.pipeline` with **no** `traverse-cli serve`. See [`embedded-runtime-plan.md`](embedded-runtime-plan.md).

## App Registration (Phase 2 — dev sidecar)

Governed by `044-application-bundle-manifest` and `046-public-cli-app-registration` (both approved).

```bash
traverse-cli app validate --manifest manifests/<app>/app.manifest.json --json

traverse-cli app register \
  --manifest manifests/<app>/app.manifest.json \
  --workspace local-default \
  --json
```

Phase 3 production builds embed manifests + WASM at **build time**; registration into a sidecar workspace is not the shipping path.

## Local Development Override

```bash
export TRAVERSE_REPO=/path/to/Traverse
cd $TRAVERSE_REPO && cargo run -p traverse-cli -- serve
```

Do not commit `TRAVERSE_REPO` references into app code.

## CI Environment

```bash
TRAVERSE_RUNTIME_URL=http://<host>:<port>
TRAVERSE_WORKSPACE_ID=local-default
```

`scripts/ci/phase1_smoke.sh` reads these when `.traverse/server.json` is absent.

Phase 2:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
bash scripts/ci/phase2_smoke.sh
```

Phase 3:

```bash
export TRAVERSE_REPO=/path/to/Traverse
export EMBEDDED_SMOKE_REQUIRED_SLICES=web,rust-cli
bash scripts/ci/embedded_smoke.sh
```
