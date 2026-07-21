# Phase 4 — Production Reference Plan

## Purpose

Phase 3 delivered **embedded Traverse runtime** on the primary UI shells (Web, Linux/CLI, Windows, Apple, Android). This repo’s next job is to become the **production reference kit**: the copy-paste pattern for shipping real multi-OS Traverse apps — not only demos.

Status of individual tickets lives on [Project 2](https://github.com/orgs/traverse-framework/projects/2) only (Draft tickets with Spec + DoD). This document is the narrative and decision log; do not treat ticket lists here as live status. See [`ticket-standard.md`](ticket-standard.md).

Related:

- Phase 3 architecture: [`embedded-runtime-plan.md`](embedded-runtime-plan.md)
- Production playbook: [`production-playbook.md`](production-playbook.md)
- Hands-on embed path: [`getting-started-embedded.md`](getting-started-embedded.md)
- Sidecar (deprecated appendix): [`traverse-runtime.md`](traverse-runtime.md)

## Mission (locked)

**Hybrid:** harden the production kit first, then prove it with one showcase.

1. **Kit** — CI proof, packaging/digest sync, embedded-first docs, agent/dev DoD  
2. **Showcase** — extend **meeting-notes** to multi-OS by following the playbook (not a greenfield domain app first)

## Locked decisions

| Topic | Decision | Recorded on |
|---|---|---|
| Claim order | Parallel lanes; embedded smoke was merge-priority for the kit | Brainstorm |
| Native CI | **Tiered:** PR merge-blocking = Linux (`cargo`); Nightly = Apple + Windows required; Android/GTK promote via `native-ci-android-gtk-required` | Project 2 / quality-standards |
| Embedded smoke | **One script, all platforms**; skip-with-reason when SDK missing; hard-fail when the runner is expected to run that slice | Project 2 (Done) |
| HTTP sidecar | **Freeze & archive**, then delete (`remove-sidecar-paths`) | Decision C |
| Trace Explorer | **Named HTTP exception** until Traverse ships embedded trace API; then `embed-trace-explorer` | Decision B |
| Post-kit showcase | **meeting-notes → multi-OS** (`meeting-notes-multi-os`) via add-platform recipe | Decision A |
| Plan home | This document | Project 2 (Done) |
| Registry | **Docs contract** shipped; **impl** `registry-ref-starter-process` (Blocked on upstream) | Decision C |
| Secondary apps | **Explicitly secondary** (demos/kits); not hard-fail smoke targets | Project 2 (Done) |
| Repo front door | Embedded-first README + playbook; sidecar appendix-only | Decision B |
| Digest sync | **Shared core + thin per-platform wrappers** — see [`runtime-bundle-sync.md`](runtime-bundle-sync.md) | Decision B |
| Showcase rollout | **Wave 1:** Web + Linux/CLI (+ Android if stable); **Wave 2:** Windows + Apple | Decision C |
| Product agents | Smoke fixtures today; adopt Traverse agents via `consume-product-wasm-agents` | Gap capture |

### Primary vs secondary (locked)

| Tier | Apps | Smoke / CI bar |
|---|---|---|
| **Primary product shells** | `traverse-starter`, `doc-approval`, `meeting-notes` | Production DoD; Linux-runnable `embedded_smoke` hard-fail |
| **Adopted / secondary** | `react-demo`, `android-demo`, `macos-demo`, `browser-consumer`, `youaskm3-starter-kit` | Lighter demo smokes only — **not** merge-blocking `embedded_smoke` targets |
| **Debugger exception** | `trace-explorer` | Not a product shell; named HTTP until `embed-trace-explorer` |

Canonical narrative: [`adopted-platform-clients.md`](adopted-platform-clients.md) · front door: root `README.md`.

## Gap → ticket → start plan

Live status is always on [Project 2](https://github.com/orgs/traverse-framework/projects/2). Mapping from the demo-gap list:

| Demo gap | Ticket ID | Board | Why it matters | Start plan |
|---|---|---|---|---|
| meeting-notes multi-OS embed | `meeting-notes-multi-os` | **In Progress** (Cursor) | Web + Linux GTK + CLI embed | Finish PR; Apple/Windows later waves |
| Trace Explorer embed | `embed-trace-explorer` | **Blocked** | Still HTTP; needs Traverse embedded trace API | Do not start — flip Ready when upstream API exists |
| meeting-notes multi-OS embed | `meeting-notes-multi-os` | **Done** | Web + Linux GTK + CLI embed | Shipped |
| Trace Explorer embed | `embed-trace-explorer` | **Blocked** | Still HTTP; needs Traverse embedded trace API | Do not start — flip Ready when upstream API exists |
| Delete sidecar client code | `remove-sidecar-paths` | **Done** | Dead HTTP paths removed from starter/doc-approval | Shipped |
| Nightly Apple/Windows + Android/GTK | `native-ci-android-gtk-required` | **In Progress** (Cursor) | GTK + Android compile fixes; jobs required on nightly | Finish PR |
| Product WASM agents (Traverse) | `consume-product-wasm-agents` | **Blocked** | Smoke uses App-Refs fixtures; Traverse agents still stubs | Wait Traverse (e.g. #785); then swap fixtures |
| `registry_ref` adoption | `registry-ref-starter-process` | **Blocked** | Registry seed + sync Done; Traverse still requires `contract_path` on component manifests (spec 054 FR-007 not wired) | Wait Traverse dual-mode component load |
| Phase 2 sidecar nightly | `phase2-sidecar-nightly` | **Future** (defer) | Legacy path; low demo value | After Wave 1; optional |

### Wave 1 — start now (Ready, parallel OK)

1. **`remove-sidecar-paths`** — cleanup primary shells  
2. **`meeting-notes-multi-os`** — showcase embed  
3. **`native-ci-android-gtk-required`** — CI bar  

One Project 2 ticket per agent (`AGENTS.md`). Claim only `Ready` + Agent Unassigned.

### Wave 2 — after upstream unblocks

Flip Status → Ready when Depends on clears, then claim:

- `embed-trace-explorer`
- `registry-ref-starter-process`
- `consume-product-wasm-agents`

## Architecture boundary (unchanged)

- UI shells render runtime-owned fields only — no local business logic  
- Public Traverse embedder APIs only — no private internals  
- Tests use host SDK doubles (`InMemoryTraverseEmbedder` / platform equivalent), never fake title/tags/recommendations in app code  
- Production path = **embedded** WASM host; sidecar is deprecated interim only  

## Exit criteria for Phase 4 kit

1. `bash scripts/ci/embedded_smoke.sh` exists and is wired to CI with the skip/fail contract above — **met**
2. Tiered native CI documented in `docs/quality-standards.md` and implemented for the Linux PR gate — **met** (Android/GTK still advisory → `native-ci-android-gtk-required`)
3. Digest sync + packaging playbook published — **met**
4. Getting-started / README are embedded-first; sidecar appendix-only — **met**
5. Agent DoD + add-platform recipe published — **met**
6. Wave 1 Ready tickets above — execute in start order (#1 → #3)

When open tickets complete, update Project 2 Status → Done — do not invent a separate status field outside Project 2.
