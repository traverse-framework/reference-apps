# loop (Web React UI)

**Runtime mode: Embedded** — in-app WASM via the public `traverse-embedder-web` package (`BundleEmbedder` + `FetchBundleLoader`). No `traverse-cli serve` sidecar is required.

React UI shell for the **loop** reference application — a second domain app that demonstrates **list-type structured output** from the Traverse runtime.

Paste a meeting transcript → the runtime returns action items, decisions, follow-ups, and a summary. The UI renders those fields only; it does not extract or invent them.

## What this demonstrates vs traverse-starter

| | traverse-starter | loop |
|---|---|---|
| Input | Short note (`note`, 2000 chars) | Longer transcript (`transcript`, 5000 chars) |
| Output shape | Flat string fields + string tags | Object arrays (`action_items`, `decisions`) + string list + summary |
| Workflow | `traverse-starter.pipeline` | `loop.wf1` |

## Core Design Principles

1. **UI is a rendering layer only** — `action_items`, `decisions`, `follow_ups`, and `summary` come from the runtime. The UI displays them; it does not compute them.
2. **Strict boundary isolation** — no private Traverse internals are imported. All communication uses public embedder surfaces.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `VITE_LOOP_MANIFEST` | `/bundles/loop/app.manifest.json` | FetchBundleLoader manifest path |

Sync a local bundle (requires `TRAVERSE_REPO`):

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_web_loop_bundle.sh
```

## Development Commands

From the **repository root**:

```bash
npm install
npm run dev -w apps/loop/web-react
npm run build -w apps/loop/web-react
npm run typecheck -w apps/loop/web-react
npm run lint -w apps/loop/web-react
npm run test -w apps/loop/web-react
npm run test:coverage -w apps/loop/web-react
```

Production guide: [`docs/production-playbook.md`](../../../docs/production-playbook.md).
