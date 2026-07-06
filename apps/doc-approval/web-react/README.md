# doc-approval (Web React UI)

React UI shell for the **doc-approval** reference application. Phase 1 covers the **submitter surface** only: paste document text, execute via the Traverse HTTP/JSON API, poll for completion, and render runtime-provided analysis fields.

## Core Design Principles

1. **UI is a rendering layer only** — analysis fields (docType, parties, amounts, confidence, recommendation) come from the runtime. The UI displays them; it does not compute them.
2. **Strict boundary isolation** — no private Traverse internals are imported. All communication uses public runtime surfaces.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `VITE_TRAVERSE_BASE_URL` | `http://127.0.0.1:8787` | Runtime base URL |
| `VITE_TRAVERSE_WORKSPACE` | `local-default` | Workspace ID |
| `VITE_TRAVERSE_CAPABILITY_ID` | `doc-approval.analyze` | Capability to execute |

Legacy alias: `VITE_TRAVERSE_RUNTIME_URL` is accepted as a fallback for `VITE_TRAVERSE_BASE_URL`.

Copy or edit `apps/doc-approval/web-react/.env`:

```bash
VITE_TRAVERSE_BASE_URL=http://127.0.0.1:8787
VITE_TRAVERSE_WORKSPACE=local-default
VITE_TRAVERSE_CAPABILITY_ID=doc-approval.analyze
```

## Start the Traverse Runtime

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

The doc-approval capability must be registered in the runtime before execute calls succeed. See the Traverse repo for domain capability setup.

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

## Phase 2 Upgrade Path

When Traverse ships state machine, SSE, command dispatch, and session listing:

- Replace polling with SSE subscription
- Add approver surface: session queue, approve/reject commands
- Conditional transitions (e.g. auto-approve when confidence ≥ 0.85)

Do not implement Phase 2 in this scaffold.
