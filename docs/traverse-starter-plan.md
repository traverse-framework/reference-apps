# traverse-starter Plan

## Purpose

`traverse-starter` is a reference UI application that demonstrates integrating a React frontend with the Traverse runtime. It is the canonical example of what an app built on Traverse looks like from the outside: a thin UI layer that starts workflows, receives events, and renders runtime-provided structured output — without owning any business logic.

## Architecture Boundary

**This repo is UI-only.**

| Concern | Lives in |
|---|---|
| React UI shell | This repo (`apps/traverse-starter/web-react`) |
| Runtime event client | This repo (thin boundary layer only) |
| Business logic (tags, note type, next action, status) | Traverse runtime (external) |
| App/workflow manifests | This repo (`manifests/`) |
| Traverse CLI/runtime binary | External — pinned release or `TRAVERSE_REPO` override |

The React UI must not compute business fields. It renders, sorts, filters, and displays data provided by the runtime.

## Accepted Decisions

- Phase 1 does not require live AI/model access. Traversal determinism is guaranteed by the runtime.
- No private Traverse internals are imported into this repo.
- No HTTP app registration endpoint in Phase 1.
- No service registry in Phase 1.
- No fake business logic or fake registration in the UI.
- The canonical consumer path uses a pinned released Traverse runtime/CLI.
- A `TRAVERSE_REPO=/path/to/Traverse` env override is supported for active framework development only.

## Traverse Dependency Model

```bash
# Default: pinned released Traverse CLI/runtime (version pinned in package.json or lockfile)
npx traverse-cli ...

# Override for framework development only
TRAVERSE_REPO=/path/to/Traverse npx traverse-cli ...
```

Do not assume the Traverse repo is present unless the user or repo docs confirm it.

## Phase 1 Scope

Goal: prove the UI-to-runtime integration path end-to-end with no live AI dependency.

### Deliverables

1. **UI shell** — `apps/traverse-starter/web-react`
   - Starts locally
   - Contains no Traverse business logic
   - Configured with local Traverse runtime URL/discovery
   - Documents pinned Traverse release and `TRAVERSE_REPO` override behavior

2. **Runtime event client boundary**
   - React starts a workflow through a public Traverse runtime/client interface
   - React subscribes to correlated runtime events
   - UI state is driven by events (loading, progress, failure, final)
   - No private Traverse internals imported

3. **Deterministic UI flow**
   - User enters a short note/starter input
   - UI sends input to Traverse runtime
   - UI renders runtime-provided fields: title, tags, note type, suggested next action, workflow/event status
   - UI does not compute these fields locally

4. **Phase 1 smoke test**
   - Starts or connects to local Traverse runtime
   - Starts the React app or tests the app boundary
   - Verifies: workflow start → event receipt → final rendered output
   - Output is concise and CI-friendly

### Business Fields (runtime-owned, UI renders only)

- Title
- Deterministic tags
- Note type
- Suggested next action
- Workflow/event status

## Phase 2 Scope

Goal: prove that app validation and registration via the Traverse public CLI surface work end-to-end.

### Target Commands

```bash
traverse-cli app validate --manifest <path> --json
traverse-cli app register --manifest <path> --workspace <workspace-id> --json
```

### Deliverables

1. App can validate Traverse app manifest and component manifests.
2. App can register into durable local Traverse workspace state.
3. Local runtime can load the registered app/workflow state.
4. UI can invoke the registered workflow.
5. Deterministic smoke test proves the end-to-end path.

**Phase 2 is blocked** until the Traverse release exposes the public app validation/registration CLI surface above. Do not fake registration in this repo.

## Proposed Smoke Tests

### Phase 1

```
smoke-test:phase1
  1. Start local Traverse runtime (or stub)
  2. Start React app (or invoke app boundary directly)
  3. POST start-workflow with fixture input
  4. Assert events received: [started, progress, completed]
  5. Assert rendered output contains runtime-provided fields (non-empty, not UI-computed)
  6. Exit 0 on pass, exit 1 with diff on fail
```

### Phase 2

```
smoke-test:phase2
  1. Run: traverse-cli app validate --manifest manifests/app.json --json
  2. Assert: exit 0, valid JSON response
  3. Run: traverse-cli app register --manifest manifests/app.json --workspace <id> --json
  4. Assert: registered state is durable (re-query confirms)
  5. Start runtime with registered app
  6. Run Phase 1 smoke test against registered workflow
  7. Exit 0 on pass
```

## Open Questions

1. What is the current pinned Traverse CLI version? Where is the release artifact?
2. What does the Traverse runtime event client public interface look like (HTTP SSE, WebSocket, SDK)?
3. What is the local runtime discovery mechanism (env var, config file, fixed port)?
4. What fields does the runtime guarantee in the final workflow output event?
5. Is there an existing app manifest schema, or does it need to be defined?
6. Does Phase 2 CLI registration exist in any released or pre-release Traverse build?

## Ticket Breakdown

### Ticket 1: Define `traverse-starter` UI-only reference app plan
**Status: Done** — this document.

DoD:
- [x] Planning doc exists
- [x] App boundary is explicit: UI-only in this repo
- [x] Traverse runtime/business assets identified as external dependencies
- [x] Phase 1 and Phase 2 separated
- [x] No implementation scaffolding required beyond planning

---

### Ticket 2: Scaffold web React UI shell for `traverse-starter`

DoD:
- `apps/traverse-starter/web-react` exists
- UI shell starts locally
- Contains no Traverse business logic
- Has configuration for local Traverse runtime URL/discovery
- Documents pinned Traverse release and `TRAVERSE_REPO` override behavior

---

### Ticket 3: Add runtime event client boundary for web React

DoD:
- React can start a workflow through a public Traverse runtime/client boundary
- React subscribes to correlated runtime events
- UI state is driven by events
- Failure, loading, progress, and final states are visible
- No private Traverse internals imported

---

### Ticket 4: Add deterministic traverse-starter UI flow

DoD:
- User can enter a short note or starter input
- UI sends input to Traverse runtime
- UI renders runtime-provided structured result fields
- UI does not compute title/tags/type/next-action locally
- Feature is deterministic (no live AI/model access required)

---

### Ticket 5: Add Phase 1 smoke test

DoD:
- Smoke test starts or connects to local Traverse runtime
- Smoke test starts the React app or tests the app boundary
- Verifies: workflow start → event receipt → final rendered output
- Output is concise and CI-friendly

---

### Ticket 6: Track Phase 2 app validation/registration integration

**Status: Blocked** — waiting on Traverse public app validation/registration CLI surface.

DoD:
- Phase 2 dependency documented (this doc, Phase 2 section)
- Target commands listed
- Task remains blocked until required Traverse release exists
- No fake registration path introduced
