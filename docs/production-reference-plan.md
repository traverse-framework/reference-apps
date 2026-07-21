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

## Ticket map (kit → remaining)

Query Project 2 for current Status / Agent. Kit tickets are **Done**. Remaining open work (by **Ticket ID**):

### After kit (Future)

| Ticket ID | Intent |
|---|---|
| `remove-sidecar-paths` | Remove deprecated HTTP sidecar paths from primary app clients |
| `meeting-notes-multi-os` | meeting-notes multi-OS showcase |
| `native-ci-android-gtk-required` | Promote Android + GTK CI from advisory to required |
| `phase2-sidecar-nightly` | Phase 2 sidecar smoke on nightly (low priority) |

### Blocked (upstream)

| Ticket ID | Intent |
|---|---|
| `embed-trace-explorer` | Embed Trace Explorer when Traverse ships embedded trace API |
| `registry-ref-starter-process` | `registry_ref` for traverse-starter process |
| `consume-product-wasm-agents` | Replace App-Refs smoke fixtures with Traverse product agents |

## Parallel agent lanes (recommended)

| Lane | Tickets | Notes |
|---|---|---|
| Showcase | `meeting-notes-multi-os` | After flipping Future → Ready |
| Cleanup | `remove-sidecar-paths` | After flipping Future → Ready |
| CI harden | `native-ci-android-gtk-required` | Engineering only |
| Upstream-gated | Blocked tickets above | Flip Ready only when Depends on clear |

One Project 2 ticket per agent (`AGENTS.md` claim rules). Do not claim Future/Blocked items until Status is `Ready`.

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
6. Next: flip `remove-sidecar-paths` / `meeting-notes-multi-os` to Ready and execute

When open tickets complete, update Project 2 Status → Done — do not invent a separate status field outside Project 2.
