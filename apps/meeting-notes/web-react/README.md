# meeting-notes (Web React UI)

**Runtime mode: HTTP sidecar (temporary)** — web-only until the multi-OS embed showcase ([#179](https://github.com/traverse-framework/reference-apps/issues/179)). This is a **primary product shell** (list-type output); sidecar is interim only — see [`docs/production-playbook.md`](../../../docs/production-playbook.md) and the primary vs secondary table in the root README.

React UI shell for the **meeting-notes** reference application — a second domain app that demonstrates **list-type structured output** from the Traverse runtime.

Paste a meeting transcript → the runtime returns action items, decisions, follow-ups, and a summary. The UI renders those fields only; it does not extract or invent them.

## What this demonstrates vs traverse-starter

| | traverse-starter | meeting-notes |
|---|---|---|
| Input | Short note (`note`, 2000 chars) | Longer transcript (`transcript`, 5000 chars) |
| Output shape | Flat string fields + string tags | Object arrays (`action_items`, `decisions`) + string list + summary |
| Capability default | `traverse-starter.process` | `meeting-notes.process` |

Same Phase 1 HTTP/JSON client pattern; richer rendering of runtime-owned list schemas.

## Core Design Principles

1. **UI is a rendering layer only** — `action_items`, `decisions`, `follow_ups`, and `summary` come from the runtime. The UI displays them; it does not compute them.
2. **Strict boundary isolation** — no private Traverse internals are imported. All communication uses public runtime surfaces.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `VITE_TRAVERSE_BASE_URL` | `http://127.0.0.1:8787` | Runtime base URL |
| `VITE_TRAVERSE_WORKSPACE` | `local-default` | Workspace ID |
| `VITE_TRAVERSE_CAPABILITY_ID` | `meeting-notes.process` | Capability to execute |

Legacy alias: `VITE_TRAVERSE_RUNTIME_URL` is accepted as a fallback for `VITE_TRAVERSE_BASE_URL`.

Copy or edit `apps/meeting-notes/web-react/.env`:

```bash
VITE_TRAVERSE_BASE_URL=http://127.0.0.1:8787
VITE_TRAVERSE_WORKSPACE=local-default
VITE_TRAVERSE_CAPABILITY_ID=meeting-notes.process
```

## Start the Traverse Runtime

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

The `meeting-notes.process` capability must be registered in the runtime before execute calls succeed. See Traverse [#532](https://github.com/traverse-framework/Traverse/issues/532) / the Traverse repo for domain capability setup.

## Development Commands

From the **repository root**:

```bash
npm install
npm run dev -w apps/meeting-notes/web-react
npm run build -w apps/meeting-notes/web-react
npm run typecheck -w apps/meeting-notes/web-react
npm run lint -w apps/meeting-notes/web-react
npm run test -w apps/meeting-notes/web-react
npm run test:coverage -w apps/meeting-notes/web-react
```
