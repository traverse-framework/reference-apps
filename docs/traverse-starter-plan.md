# traverse-starter Plan

## Purpose

`traverse-starter` is the minimal Traverse reference UI app. It demonstrates the full app-consumable path for downstream developers:

- **Phase 1**: UI → HTTP execute → poll → render runtime-provided structured output
- **Phase 2**: app manifest → `traverse-cli app validate` → `traverse-cli app register` → runtime loads registered capability → UI invokes it end-to-end

## Architecture Boundary

**This repo is UI-only.**

| Concern | Lives in |
|---|---|
| React UI shell | This repo — `apps/traverse-starter/web-react` |
| HTTP client boundary (spec 033) | This repo |
| App manifest + component manifests | This repo — `manifests/traverse-starter/` |
| Capability contract + WASM agent | Traverse repo — `examples/traverse-starter/` |
| Business output fields (title, tags, etc.) | Traverse runtime — UI renders, never computes |
| Traverse CLI/runtime binary | External — pinned (see below) |

## Runtime Pin

| Phase | Minimum Traverse version |
|---|---|
| Phase 1 (HTTP integration) | v0.3.0 |
| Phase 2 (CLI app registration) | v0.5.0 |

Start the runtime:

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout <version>
cargo run -p traverse-cli -- serve
# Writes .traverse/server.json
```

Override for active Traverse development:

```bash
TRAVERSE_REPO=/path/to/Traverse
cd $TRAVERSE_REPO && cargo run -p traverse-cli -- serve
```

## API Surface (spec 033-http-json-api, approved v1.1.0)

| Endpoint | Method | Purpose |
|---|---|---|
| `/healthz` | GET | Health check |
| `/v1/workspaces/{workspace_id}/execute` | POST | Execute a capability |
| `/v1/workspaces/{workspace_id}/executions/{execution_id}` | GET | Poll execution status |
| `/v1/workspaces/{workspace_id}/traces/{execution_id}` | GET | Fetch public trace |

Discovery: `.traverse/server.json` → `base_url`, `workspace_default`

In the browser (env vars):

```
VITE_TRAVERSE_BASE_URL=http://127.0.0.1:8787
VITE_TRAVERSE_WORKSPACE=local-default
```

## Phase 1 — HTTP Integration

**Status: complete**

**Deliverables (all merged):**

1. **UI shell** — `apps/traverse-starter/web-react` (issue #2)
2. **Runtime HTTP client** — `src/client/traverseClient.ts` + `src/hooks/useExecution.ts` (issue #3)
3. **Deterministic UI flow** — renders `title`, `tags`, `noteType`, `suggestedNextAction`, `status` from runtime output; computes none locally (issue #4)
4. **Phase 1 smoke test** — `scripts/ci/phase1_smoke.sh` (issue #5); set `TRAVERSE_RUNTIME_URL` to activate

**Capability invoked:** `traverse-starter.process`
**Input:** `{ "note": string }`
**Output (runtime-owned):** `{ "title", "tags", "noteType", "suggestedNextAction", "status" }`

## Phase 2 — App Registration

**Status: unblocked — Traverse #499 and #500 merged**

**Governing specs:** `044-application-bundle-manifest`, `046-public-cli-app-registration`

**Deliverables:**

1. App manifest at `manifests/traverse-starter/app.manifest.json` (issue #24)
2. Component manifest at `manifests/traverse-starter/components/process/component.manifest.json`
3. `traverse-cli app validate --manifest manifests/traverse-starter/app.manifest.json --json` → exit 0
4. `traverse-cli app register --manifest manifests/traverse-starter/app.manifest.json --workspace local-default --json`
5. Phase 2 smoke test — `scripts/ci/phase2_smoke.sh` (issue #6)

**Setup:** manifests reference WASM/contracts/workflows in Traverse via symlink:

```bash
export TRAVERSE_REPO=/path/to/Traverse   # main branch, v0.5.0+
bash scripts/ci/phase2_link_traverse.sh  # creates manifests/traverse-starter/_traverse
cd $TRAVERSE_REPO && cargo run -p traverse-cli -- serve
bash scripts/ci/phase2_smoke.sh
```

## Ticket Index

| # | Title | Status |
|---|---|---|
| 1 | Define traverse-starter plan | ✅ Done |
| 2 | Scaffold web React UI shell | ✅ Done |
| 3 | Add runtime event client boundary | ✅ Done |
| 4 | Add deterministic UI flow | ✅ Done |
| 5 | Add Phase 1 smoke test | ✅ Done |
| 24 | Author traverse-starter app manifest | ✅ Ready (Traverse #499 merged) |
| 6 | Phase 2 app registration | ✅ Ready (Traverse #499, #500 merged) |

## Accepted Decisions

- UI renders runtime-provided fields only — no local business logic
- No private Traverse internals imported
- No HTTP app registration endpoint — setup uses CLI only
- No service registry — discovery via `.traverse/server.json`
- No fake runtime responses in application code
- Phase 1 does not require live AI/model access — runtime determinism is guaranteed
- `TRAVERSE_REPO` env override is for active framework development only
