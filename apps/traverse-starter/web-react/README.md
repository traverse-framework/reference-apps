# traverse-starter (Web React UI)

**Runtime mode: embedded** — in-app WASM via the public `traverse-embedder-web` package (`BundleEmbedder` + `FetchBundleLoader`). No `traverse-cli serve` sidecar is required.

React UI shell for the `traverse-starter` reference application. The UI submits note input and renders runtime-owned output only.

## Core Design Principles

1. **UI is a rendering layer only** — business fields (title, tags, note type, suggested next action, status) come from the runtime. The UI displays them; it does not compute them.
2. **Strict boundary isolation** — no private Traverse internals are imported. All communication uses public embedder surfaces.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `VITE_TRAVERSE_STARTER_MANIFEST` | `/bundles/traverse-starter/app.manifest.json` | FetchBundleLoader manifest path |

Sync a local bundle (requires `TRAVERSE_REPO`):

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_web_starter_bundle.sh
```

Optional **HTTP sidecar (Phase 1/2 interim)** is not the production path for this client. Prefer the embedded host above. Sidecar docs live in [`docs/traverse-runtime.md`](../../../docs/traverse-runtime.md) for platforms still blocked on [#114](https://github.com/traverse-framework/reference-apps/issues/114)–[#116](https://github.com/traverse-framework/reference-apps/issues/116).

## Development Commands

Run from the **repository root**:

```bash
npm install
npm run dev          # starts traverse-starter embedded web shell
npm run build
npm run typecheck
npm run lint
npm run test
npm run test:coverage
```

Open `http://localhost:5173`. When the embedded host is ready, submit a note and confirm runtime-owned fields render in the output panel.
