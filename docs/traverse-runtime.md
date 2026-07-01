# Traverse Runtime Setup

This document is the canonical local setup reference for all apps in this repo.

## Pinned Version

| Phase | Minimum version | Adds |
|---|---|---|
| Phase 1 (HTTP integration) | **v0.3.0** | HTTP/JSON API, `/healthz`, execute, poll, trace |
| Phase 2 (CLI app registration) | **v0.5.0** | `traverse-cli app validate/register`, workspace state |

Requirements: Rust 1.94+

## Start the Runtime

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse
git checkout v0.5.0   # minimum for Phase 2; use v0.3.0 for Phase 1 only
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

## API Surface

Governed by `033-http-json-api` (approved v1.1.0).

| Endpoint | Method | Purpose |
|---|---|---|
| `/healthz` | GET | Health check |
| `/v1/workspaces/{workspace_id}/execute` | POST | Execute a capability |
| `/v1/workspaces/{workspace_id}/executions/{execution_id}` | GET | Poll execution status |
| `/v1/workspaces/{workspace_id}/traces/{execution_id}` | GET | Fetch public trace |
| `/v1/workspaces/{workspace_id}/capabilities` | POST | Register a capability |

Default workspace: `local-default`

## Discovery in App Code

```typescript
import fs from 'fs'

const server = JSON.parse(fs.readFileSync('.traverse/server.json', 'utf8'))
const baseUrl = server.base_url          // http://127.0.0.1:8787
const workspaceId = server.workspace_default  // local-default
```

In the browser (Vite dev server proxies to runtime):
```typescript
const baseUrl = import.meta.env.VITE_TRAVERSE_BASE_URL ?? 'http://127.0.0.1:8787'
const workspaceId = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'
```

## App Registration (Phase 2)

Governed by `044-application-bundle-manifest` and `046-public-cli-app-registration` (both approved).

```bash
# Validate app manifest
traverse-cli app validate --manifest manifests/<app>/app.manifest.json --json

# Register app into workspace
traverse-cli app register \
  --manifest manifests/<app>/app.manifest.json \
  --workspace local-default \
  --json
```

## Local Development Override

For active Traverse framework development, point at a local checkout instead of v0.3.0:

```bash
export TRAVERSE_REPO=/path/to/Traverse
cd $TRAVERSE_REPO && cargo run -p traverse-cli -- serve
```

Do not commit `TRAVERSE_REPO` references into app code. This is a local developer override only.

## CI Environment

For CI environments without a local runtime, set:

```bash
TRAVERSE_RUNTIME_URL=http://<host>:<port>
TRAVERSE_WORKSPACE_ID=local-default
```

The `scripts/ci/phase1_smoke.sh` reads these env vars when `.traverse/server.json` is not present.
