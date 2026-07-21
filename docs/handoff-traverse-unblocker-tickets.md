# Handoff prompt: Create missing Traverse Project 1 tickets (App-Refs unblockers)

Copy everything below the line to another agent working in **Traverse**.

---

You are working in **traverse-framework/Traverse**. Track work on **[Project 1](https://github.com/orgs/traverse-framework/projects/1) only** — create **Draft** project tickets (not GitHub Issues as the backlog). Each ticket body must include: Ticket ID, Spec, Summary, Why, Depends on, Blocked by, Definition of Done, Validation.

## Context (do not re-litigate)

App-References (`traverse-framework/reference-apps`) Project 2 already has **consumer** tickets waiting on Traverse:

| App-Refs ticket ID | Status | Waiting on |
|---|---|---|
| `registry-ref-starter-process` | Blocked | Dual-mode component manifests (this gap) |
| `consume-product-wasm-agents` | Blocked | Real WASM agent execute (partial Traverse coverage — clean up) |
| `embed-trace-explorer` | Blocked | Embedded trace API (missing entirely) |

Verified on Traverse `origin/main` (2026-07-21):

- Spec **054-public-scope-registry-ref** FR-007 requires exactly one of `contract_path` **xor** `registry_ref` per component.
- Issues/PRs **#548 / #551 / #708** are closed/Done and shipped **registry sync + verified artifact cache helpers**.
- **Gap:** `crates/traverse-registry/src/application_manifest.rs` — `WasmComponentManifestSerde.contract_path` is still a **required `String`**. There is **no** `registry_ref` field on component manifests. App-Refs cannot switch `manifests/traverse-starter/components/process/component.manifest.json` to `registry_ref` without breaking `app validate` / embedded smoke.
- Registry seed `traverse-starter.process` 1.0.0 is published (registry #21). `traverse-cli registry sync` exists (#542).
- Embedded **trace** API for in-process hosts: **no Project 1 ticket found**. Related Ready item “Decision package: durable trace-store persistence” is about store permanence, **not** an embedder/trace public API for Trace Explorer.
- Agent execute: Project 1 has a messy duplicate — same title “Functional gap: agent execute…” as both Done and Blocked; plus In Progress “Decision package: governed WASM agent artifacts”. GitHub #785 was closed as migrated to Project 1, with comments that fixture stubs still fail under real execute.

App-Refs constitution: UI-only; business logic stays in WASM. Do not invent App-Refs workarounds that compute business fields in UI.

---

## Ticket A — CREATE (critical, missing)

**Title:** Wire dual-mode component manifests (`registry_ref` xor `contract_path`) into app load  
**Ticket ID:** `dual-mode-component-registry-ref`  
**Status:** Ready (if implementable now) or Todo — **not** Done  
**Note:** `Unblocks App-Refs registry-ref-starter-process. Spec 054 FR-007. ticket-id: dual-mode-component-registry-ref`

### Spec

Implement spec **054-public-scope-registry-ref** FR-007–FR-013 for **component manifests** used by `app validate` / `app register` / embed registration paths:

- Exactly one capability source per component: local (`contract_path` + `wasm_binary_path` + `wasm_digest`) **or** `registry_ref: { namespace, id, version_range }`.
- `registry_ref` resolves **only** against sync-populated public tier (no live network at execute time).
- At registration: materialize artifacts into digest-verified content-addressed cache (reuse #708 helpers in `public_registry_cache` / `public_registry_state`).
- Failures must be actionable: never synced, no matching version, yanked, download failed, digest mismatch; registration without sync → stable “run `traverse-cli registry sync`” error.

Evidence of current gap: `WasmComponentManifestSerde` in `application_manifest.rs` still requires `contract_path: String` with no `registry_ref` field on `origin/main`.

### Depends on

Spec 054 (Done), #542 sync (Done), #551/#708 cache helpers (Done), registry publish of `traverse-starter.process` (Done).

### Blocked by

None known (engineering).

### Definition of Done

- [ ] Component manifest schema/serde accepts `registry_ref` without `contract_path` / `wasm_*`
- [ ] Manifest validation rejects both sources or neither (FR-007)
- [ ] `app validate` + `app register` succeed for an app whose **process** component uses only:
  ```json
  "registry_ref": {
    "namespace": "traverse-starter",
    "id": "traverse-starter.process",
    "version_range": "^1.0.0"
  }
  ```
  after `traverse-cli registry sync --workspace <id> --json`
- [ ] Without prior sync, register fails with stable sync-required error (spec 054 scenario 2)
- [ ] Execution reads only local durable state + cached artifacts (no network)
- [ ] Unit/integration coverage for dual-mode parse + resolve + cache hit path
- [ ] Local-path components still work unchanged (validate/process/summarize local examples)
- [ ] Docs/changelog note that App-Refs `registry-ref-starter-process` can flip Ready when this is Done

### Validation

```bash
traverse-cli registry sync --workspace local-default --json
# app whose process component is registry_ref-only:
traverse-cli app validate <manifest>
traverse-cli app register <manifest>
# negative: wipe sync state → register fails with sync-required
cargo test -p traverse-registry
# coverage gate for touched crates per repo policy
```

---

## Ticket B — CREATE (missing)

**Title:** Public embedded Trace API for in-process hosts (Trace Explorer)  
**Ticket ID:** `embedded-trace-api`  
**Status:** Future or Blocked until design decision; if “durable trace-store persistence” must land first, Status=Blocked and cite that ticket  
**Note:** `Unblocks App-Refs embed-trace-explorer. Not HTTP-only. ticket-id: embedded-trace-api`

### Spec

Ship a **public** in-process / embedder-facing Trace API so `apps/trace-explorer` in App-References can leave the HTTP sidecar exception. This is **not** the same as HTTP `033` trace fetch and **not** only durable persistence.

Must define:

- Public types/methods on the platform embedder surface (Web/native as applicable) to list/open/browse execution traces for a local embedded session
- No requirement for `traverse-cli serve` on the Trace Explorer production path
- SDK test doubles for consumers (App-Refs tests must not invent business fields)
- Explicit non-goals: product shells must not copy any remaining HTTP debug path

Related existing Project 1 item: “Decision package: durable trace-store persistence” (Ready) — link as Depends on if persistence is a prerequisite; do **not** treat it as satisfying this ticket.

### Depends on

Durable trace store decision/impl if required; public embedder API stability.

### Blocked by

Product/architecture decision if API shape unset (`needs-enrico` / decision package).

### Definition of Done

- [ ] Documented public embedded Trace API (spec + rustdoc / platform docs)
- [ ] Implement + tests + doubles on at least one host (prefer Web embedder used by Trace Explorer)
- [ ] Evidence: Trace Explorer-equivalent client can browse a local embedded session **without** `traverse-cli serve`
- [ ] App-Refs `embed-trace-explorer` can be flipped Ready with a comment linking this ticket Done

### Validation

- Unit tests for API + doubles
- Manual or scripted: embedded host produces/query traces without HTTP serve
- Spec acceptance scenarios green

---

## Ticket C — ENSURE / FIX (exists but messy)

**Title (normalize):** Real WASM execution for `traverse-cli agent execute` (replace hardcoded example executor)  
**Ticket ID:** `real-wasm-agent-execute`  
**Action:** Deduplicate Project 1 items. Keep **one** active ticket. Close/cancel the Done duplicate if work is incomplete. Align with In Progress “Decision package: governed WASM agent artifacts” — either merge DoD into that decision’s follow-up impl ticket or make this the impl ticket Depends on the decision.

**Note:** `Unblocks App-Refs consume-product-wasm-agents. ticket-id: real-wasm-agent-execute`

### Spec

`agent execute` must run **verified WASM package bytes** through the real executor (e.g. ArtifactRouter / approved runtime path), not `AgentPackageExampleExecutor` hardcoded match on demo capability IDs. GitHub #785 history and Project 1 comments document fixture/stub failures under the intended path.

### Definition of Done

- [ ] Verified `.wasm` bytes are loaded and executed (not reimplemented in native Rust stubs)
- [ ] Non-demo capabilities that pass manifest/digest/ABI gates can execute (or fail with real WASM errors, not `unsupported AI agent capability`)
- [ ] Example/reference agents used by App-Refs smoke can be consumed as Traverse-published artifacts (or clearly documented interim)
- [ ] Tests use real/minimal WASM fixtures that produce contract output — not 36-byte no-output stubs that falsely green
- [ ] App-Refs `consume-product-wasm-agents` can flip Ready when published agents + execute path work

### Validation

```bash
traverse-cli agent execute <manifest> <request>   # real WASM path
# negative: unsupported stub path gone for governed packages
cargo test -p traverse-cli   # relevant suites
```

---

## After creating tickets

1. Set Project 1 Status/Note/Agent correctly; Unassigned unless claiming.
2. Comment on (or update Notes of) App-Refs Project 2 Blocked items with the new Traverse **Ticket IDs** and flip rules:
   - `registry-ref-starter-process` → Ready when `dual-mode-component-registry-ref` is Done
   - `embed-trace-explorer` → Ready when `embedded-trace-api` is Done
   - `consume-product-wasm-agents` → Ready when `real-wasm-agent-execute` (or successor) is Done
3. Do **not** mark dual-mode Done again without the DoD evidence above — prior #551 Done was premature relative to component-manifest serde.
4. Return a table: Ticket ID | Project item title | Status | Unblocks (App-Refs ticket ID).

## Out of scope

- Do not implement App-Refs manifest switches in this task.
- Do not open App-Refs GitHub Issues for tracking.
- Do not invent UI business logic in reference-apps.
