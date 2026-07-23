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
| Trace Explorer | **Embedded Trace API** (`embed-trace-explorer`) | Decision B |
| Post-kit showcase | **meeting-notes → multi-OS** (`meeting-notes-multi-os`) via add-platform recipe | Decision A |
| Plan home | This document | Project 2 (Done) |
| Registry | **Docs contract** shipped; **impl** `registry-ref-starter-process` (Blocked on upstream) | Decision C |
| Secondary apps | **Explicitly secondary** (demos/kits); not hard-fail smoke targets | Project 2 (Done) |
| Repo front door | Embedded-first README + playbook; sidecar appendix-only | Decision B |
| Digest sync | **Shared core + thin per-platform wrappers** — see [`runtime-bundle-sync.md`](runtime-bundle-sync.md) | Decision B |
| Showcase rollout | **Wave 1:** Web + Linux/CLI (+ Android if stable); **Wave 2:** Windows + Apple | Decision C |
| Product agents | Digest-pinned Traverse-published starter agents (`consume-product-wasm-agents`) | Gap capture |

### Primary vs secondary (locked)

| Tier | Apps | Smoke / CI bar |
|---|---|---|
| **Primary product shells** | `traverse-starter`, `doc-approval`, `meeting-notes` | Production DoD; Linux-runnable `embedded_smoke` hard-fail |
| **Adopted / secondary** | `react-demo`, `android-demo`, `macos-demo`, `browser-consumer`, `youaskm3-starter-kit` | Lighter demo smokes only — **not** merge-blocking `embedded_smoke` targets |
| **Debugger** | `trace-explorer` | Embedded Trace API companion — not a product shell to copy |

Canonical narrative: [`adopted-platform-clients.md`](adopted-platform-clients.md) · front door: root `README.md`.

## Gap → ticket → start plan

Live status is always on [Project 2](https://github.com/orgs/traverse-framework/projects/2). Mapping from the demo-gap list:

| Demo gap | Ticket ID | Board | Why it matters | Start plan |
|---|---|---|---|---|
| meeting-notes multi-OS embed | `meeting-notes-multi-os` | **Done** (#208) | Web + Linux GTK + CLI embed | Shipped |
| Trace Explorer embed | `embed-trace-explorer` | **In Progress** | Traverse embedded-trace-api Done (#802); migrate web Trace Explorer | Finish PR |
| Delete sidecar client code | `remove-sidecar-paths` | **Done** (#206) | Dead HTTP paths removed from starter/doc-approval | Shipped |
| Nightly Apple/Windows + Android/GTK | `native-ci-android-gtk-required` | **Done** (#209); nightly green via `fix-nightly-native-required` | Required nightly jobs | Shipped |
| Product WASM agents (Traverse) | `consume-product-wasm-agents` | **In Progress** (#226) | Traverse real-wasm-agent-execute Done (#795/#809) | Digest-pin Traverse-published starter agents |
| `registry_ref` adoption | `registry-ref-starter-process` | **In Progress** | Process component uses `registry_ref`; sync materializes for embedders | Finish smoke evidence |
| Phase 2 sidecar nightly | `phase2-sidecar-nightly` | **Future** (defer) | Legacy path; low demo value | Optional; low priority |

### Wave 1 — Done

1. **`remove-sidecar-paths`** — shipped (#206)  
2. **`meeting-notes-multi-os`** — shipped (#208)  
3. **`native-ci-android-gtk-required`** — shipped (#209); required nightly green  

### Wave 2 — Ready (upstream unblocked 2026-07-22)

Claim when Agent is Unassigned:

- `embed-trace-explorer` (Traverse #802)
- `registry-ref-starter-process` (Traverse #811) — in progress
- `consume-product-wasm-agents` (Traverse #795/#809)

## Architecture boundary (unchanged)

- UI shells render runtime-owned fields only — no local business logic  
- Public Traverse embedder APIs only — no private internals  
- Tests use host SDK doubles (`InMemoryTraverseEmbedder` / platform equivalent), never fake title/tags/recommendations in app code  
- Production path = **embedded** WASM host; sidecar is deprecated interim only  

## Exit criteria for Phase 4 kit

1. `bash scripts/ci/embedded_smoke.sh` exists and is wired to CI with the skip/fail contract above — **met**
2. Tiered native CI documented in `docs/quality-standards.md` — **met** (Linux PR gate + required nightly macOS/Windows/Android/GTK)
3. Digest sync + packaging playbook published — **met**
4. Getting-started / README are embedded-first; sidecar appendix-only — **met**
5. Agent DoD + add-platform recipe published — **met**
6. Wave 1 tickets (#1 → #3) — **met**

When open tickets complete, update Project 2 Status → Done — do not invent a separate status field outside Project 2.
