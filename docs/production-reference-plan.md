# Phase 4 — Production Reference Plan

## Purpose

Phase 3 delivered **embedded Traverse runtime** on the primary UI shells (Web, Linux/CLI, Windows, Apple, Android). This repo’s next job is to become the **production reference kit**: the copy-paste pattern for shipping real multi-OS Traverse apps — not only demos.

Status of individual tickets lives on [Project 2](https://github.com/orgs/traverse-framework/projects/2). This document is the narrative and decision log; do not treat ticket lists here as live status.

Related:

- Phase 3 architecture: [`embedded-runtime-plan.md`](embedded-runtime-plan.md)
- Hands-on embed path: [`getting-started-embedded.md`](getting-started-embedded.md)
- Sidecar (deprecated interim): [`traverse-runtime.md`](traverse-runtime.md)

## Mission (locked)

**Hybrid:** harden the production kit first, then prove it with one showcase.

1. **Kit** — CI proof, packaging/digest sync, embedded-first docs, agent/dev DoD  
2. **Showcase** — extend **meeting-notes** to multi-OS by following the playbook (not a greenfield domain app first)

## Locked decisions

| Topic | Decision | Recorded on |
|---|---|---|
| Claim order | Parallel lanes; **#118** is merge-priority | Brainstorm |
| Native CI (#88) | **Tiered:** PR merge-blocking = Linux (`cargo`, Android `gradle` if stable); Nightly = Apple + Windows must stay green | [#88](https://github.com/traverse-framework/reference-apps/issues/88) |
| Embedded smoke (#118) | **One script, all platforms**; skip-with-reason when SDK missing; hard-fail when the runner is expected to run that slice | [#118](https://github.com/traverse-framework/reference-apps/issues/118) |
| HTTP sidecar | **Freeze & archive**, then delete after smoke is green; Trace Explorer may remain HTTP until an embedded trace API exists | [#176](https://github.com/traverse-framework/reference-apps/issues/176), [#180](https://github.com/traverse-framework/reference-apps/issues/180) |
| Post-kit showcase (#179) | **meeting-notes → multi-OS** via add-platform recipe | [#179](https://github.com/traverse-framework/reference-apps/issues/179) |
| Plan home | This document | [#181](https://github.com/traverse-framework/reference-apps/issues/181) |

## Ticket map (kit → showcase)

Query Project 2 for current Status / Agent. Intended sequencing:

### A — CI / proof

| Issue | Intent |
|---|---|
| [#118](https://github.com/traverse-framework/reference-apps/issues/118) | `scripts/ci/embedded_smoke.sh` — all-platform entrypoint |
| [#88](https://github.com/traverse-framework/reference-apps/issues/88) | Native CI builds — tiered PR vs nightly |

### B — Packaging

| Issue | Intent |
|---|---|
| [#174](https://github.com/traverse-framework/reference-apps/issues/174) | Unify digest-pinned runtime bundle sync |
| [#175](https://github.com/traverse-framework/reference-apps/issues/175) | Multi-OS packaging + release-evidence playbook |

### C — Docs / guides

| Issue | Intent |
|---|---|
| [#176](https://github.com/traverse-framework/reference-apps/issues/176) | Embedded-first production onboarding; retire sidecar-first narrative |
| [#181](https://github.com/traverse-framework/reference-apps/issues/181) | This plan doc |

### D — Agent / dev process

| Issue | Intent |
|---|---|
| [#177](https://github.com/traverse-framework/reference-apps/issues/177) | Production-shaped DoD for `/app-refs-ops` + PR template |
| [#178](https://github.com/traverse-framework/reference-apps/issues/178) | Recipe: add a new OS client from App-Refs |

### After kit (Future until kit lands)

| Issue | Intent |
|---|---|
| [#180](https://github.com/traverse-framework/reference-apps/issues/180) | Remove deprecated HTTP sidecar paths from app clients |
| [#179](https://github.com/traverse-framework/reference-apps/issues/179) | meeting-notes multi-OS showcase |

### Lower priority Future

| Issue | Intent |
|---|---|
| [#89](https://github.com/traverse-framework/reference-apps/issues/89) | Phase 2 sidecar smoke on nightly (sidecar path; below #118) |
| [#97](https://github.com/traverse-framework/reference-apps/issues/97) | `registry_ref` for traverse-starter process (registry-gated) |

## Parallel agent lanes (recommended)

| Lane | Tickets | Merge priority |
|---|---|---|
| Proof | #118 → #174 | Highest |
| Docs | #176 (after #181) → #175 | Medium |
| Ops | #177 → #178 | Medium |
| Native CI | #88 (tiered) | After Linux slice of #118 is green |

One issue per agent (`AGENTS.md` claim rules). Do not claim Future items until their Depends on are Done.

## Architecture boundary (unchanged)

- UI shells render runtime-owned fields only — no local business logic  
- Public Traverse embedder APIs only — no private internals  
- Tests use host SDK doubles (`InMemoryTraverseEmbedder` / platform equivalent), never fake title/tags/recommendations in app code  
- Production path = **embedded** WASM host; sidecar is deprecated interim only  

## Exit criteria for Phase 4 kit

1. `bash scripts/ci/embedded_smoke.sh` exists and is wired to CI with the skip/fail contract above  
2. Tiered native CI documented in `docs/quality-standards.md` and implemented for the Linux PR gate  
3. Digest sync + packaging playbook published  
4. Getting-started / README are embedded-first; sidecar appendix-only  
5. Agent DoD + add-platform recipe published  
6. Then: flip #180 / #179 Ready and execute  

When the kit exit criteria are met, update this section’s checklist in the PR that closes the last kit ticket — do not invent a separate status field outside Project 2.
