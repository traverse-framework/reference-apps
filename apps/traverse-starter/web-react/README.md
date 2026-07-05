# traverse-starter (Web React UI)

This is the React UI shell for the `traverse-starter` reference application. It is a thin presentation layer that connects to the Traverse runtime over the public HTTP/JSON API (spec 033).

## Core Design Principles

1. **UI is a rendering layer only** — business fields (title, tags, note type, suggested next action, status) come from the runtime. The UI displays them; it does not compute them.
2. **Strict boundary isolation** — no private Traverse internals are imported. All communication uses public runtime surfaces.

## Configuration & Runtime Discovery

The app reads runtime settings from Vite env vars. Defaults match a local `traverse-cli serve` instance:

| Variable | Default | Purpose |
|---|---|---|
| `VITE_TRAVERSE_BASE_URL` | `http://127.0.0.1:8787` | Runtime base URL (`/healthz`, execute, poll, trace) |
| `VITE_TRAVERSE_WORKSPACE` | `local-default` | Workspace ID |
| `VITE_TRAVERSE_CAPABILITY_ID` | `traverse-starter.process` | Capability to execute |

Legacy alias: `VITE_TRAVERSE_RUNTIME_URL` is accepted as a fallback for `VITE_TRAVERSE_BASE_URL`.

Copy or edit `apps/traverse-starter/web-react/.env`:

```bash
VITE_TRAVERSE_BASE_URL=http://127.0.0.1:8787
VITE_TRAVERSE_WORKSPACE=local-default
VITE_TRAVERSE_CAPABILITY_ID=traverse-starter.process
```

On startup, the runtime writes `.traverse/server.json` with `base_url` and `workspace_default` — use those values if your port differs.

See [docs/traverse-runtime.md](../../../docs/traverse-runtime.md) for pinned versions and Phase 1 vs Phase 2 requirements.

## Start the Traverse Runtime

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0   # or v0.3.0+ for Phase 1 HTTP only
cargo run -p traverse-cli -- serve
```

For active Traverse framework development:

```bash
export TRAVERSE_REPO=/path/to/Traverse
cd "$TRAVERSE_REPO" && cargo run -p traverse-cli -- serve
```

Do not commit `TRAVERSE_REPO` into app code — it is a local developer override only.

## Development Commands

Run from the **repository root**:

```bash
npm install
npm run dev          # starts traverse-starter dev server
npm run build
npm run typecheck
npm run lint
npm run test
npm run test:coverage
```

## Smoke Tests

```bash
# Phase 1 — requires runtime at 127.0.0.1:8787 (or TRAVERSE_RUNTIME_URL)
bash scripts/ci/phase1_smoke.sh

# Phase 2 — requires TRAVERSE_REPO pointing at Traverse main/v0.5.0+
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_smoke.sh
```
