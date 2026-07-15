# doc-approval (Web React UI)

React UI shell for the **doc-approval** reference application. Submitter surface: paste document text, run `doc-approval.pipeline` via the embedded Traverse host (or HTTP execute on platforms still on sidecar), and render runtime-provided analysis + recommendation fields.

## Core Design Principles

1. **UI is a rendering layer only** — pipeline fields (`analysis.*`, `recommendation.*`) come from the runtime. The UI displays them; it does not compute them.
2. **Strict boundary isolation** — no private Traverse internals are imported. All communication uses public runtime surfaces.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `VITE_DOC_APPROVAL_MANIFEST` | `/bundles/doc-approval/app.manifest.json` | FetchBundleLoader manifest path |

Sync a local bundle (requires `TRAVERSE_REPO`):

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_web_doc_approval_bundle.sh
```

## Development Commands

From the **repository root**:

```bash
npm install
npm run dev -w apps/doc-approval/web-react
npm run build -w apps/doc-approval/web-react
npm run typecheck -w apps/doc-approval/web-react
npm run lint -w apps/doc-approval/web-react
npm run test -w apps/doc-approval/web-react
npm run test:coverage -w apps/doc-approval/web-react
```
