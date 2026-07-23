# Traverse Runtime — Dev Sidecar (Deprecated Appendix)

> **Production path is embedded.** Start with [`production-playbook.md`](production-playbook.md) and [`getting-started-embedded.md`](getting-started-embedded.md).  
> This page is an **appendix** for historical Phase 1/2 HTTP integration, named HTTP carve-outs, and legacy smoke scripts. Do **not** treat sidecar as the default for new primary shells.

## Named HTTP carve-outs (exception list)

These paths may still reference `127.0.0.1:8787` / Runtime URL:

| Path | Ticket / note |
|---|---|
| This appendix + legacy `phase1_smoke.sh` / nightly sidecar checks | Historical Phase 1/2 only |

`apps/trace-explorer/**` is **Embedded** (Project 2 `embed-trace-explorer` — uses `embedded-trace-api/1.0.0`).

Primary shells (traverse-starter, doc-approval, meeting-notes on Web/Linux/CLI) are **Embedded-only** — no Runtime URL settings, no health polling against a sidecar.

## Deployment Models

| Model | Status | Use when |
|---|---|---|
| **Embedded in-app host (Phase 3)** | **Shipped** on primary platforms | Building/shipping reference apps |
| **HTTP sidecar `traverse-cli serve` (Phase 1/2)** | **Deprecated interim** | Legacy `phase1_smoke.sh` / appendix only |

End-user **primary** apps must not depend on a separately running sidecar. Sidecar cleanup: Project 2 `remove-sidecar-paths` (Done).

## Pinned Version (sidecar only)

| Phase | Minimum version | Adds |
|---|---|---|
| Phase 1 (HTTP integration) | **v0.3.0** | HTTP/JSON API, `/healthz`, execute, poll, trace |
| Phase 2 (CLI app registration) | **v0.5.0** | `traverse-cli app validate/register`, workspace state |

**Sidecar pin used in docs/scripts: v0.6.0.** Embedded hosts track public embedder packages + digest-pinned `runtime/runtime.wasm` (see [`runtime-bundle-sync.md`](runtime-bundle-sync.md)).

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

Primary operations used by reference UIs:

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/healthz` | Liveness |
| `POST` | `/v1/workspaces/{id}/execute` | Start capability |
| `GET` | `/v1/workspaces/{id}/executions/{exec_id}` | Poll status / output |
| `GET` | `/v1/workspaces/{id}/executions/{exec_id}/events` | Trace / SSE (where used) |

## Client discovery (sidecar)

```ts
// Prefer .traverse/server.json written by serve
const server = JSON.parse(fs.readFileSync('.traverse/server.json', 'utf8'))
const baseUrl = server.base_url          // http://127.0.0.1:8787
const workspace = server.workspace_default
```

Vite override (legacy / Trace Explorer):

```ts
const baseUrl = import.meta.env.VITE_TRAVERSE_BASE_URL ?? 'http://127.0.0.1:8787'
```

## App Registration (Phase 2 — dev sidecar)

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
# Then: traverse-cli app validate / register against the running sidecar
```

Phase 3 production builds embed manifests + WASM at **build time**; registration into a sidecar workspace is not the shipping path.

## Smoke tests

| Script | Path |
|---|---|
| **Embedded (production)** | `bash scripts/ci/embedded_smoke.sh` — see [`getting-started-embedded.md`](getting-started-embedded.md) |
| Phase 1 HTTP (legacy) | `bash scripts/ci/phase1_smoke.sh` — skips if no runtime configured |
| Phase 2 register (legacy) | `bash scripts/ci/phase2_smoke.sh` — needs `TRAVERSE_REPO` + sidecar |

## Related

- [`production-playbook.md`](production-playbook.md) — embedded-first shipping guide  
- [`production-reference-plan.md`](production-reference-plan.md) — Phase 4 kit decisions  
- [`embedded-runtime-plan.md`](embedded-runtime-plan.md) — Phase 3 architecture  
