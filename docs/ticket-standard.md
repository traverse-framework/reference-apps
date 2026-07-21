# Ticket Standard

This document defines the minimum quality bar for App-References issues.

## Core Rule

Every meaningful ticket must be explicit enough that a developer can tell:

- whether the work is available to start
- whether it is blocked
- what "done" means
- how to validate that it is complete
- whether it touches the UI boundary, the runtime client, or both

## Required Labels

Every active or future ticket should use the relevant labels:

- `in-progress` — currently being worked on
- `blocked` — cannot continue until blocker is resolved
- `needs-enrico` — waiting on a product or architecture decision
- `future` — valid backlog work intentionally not active now
- `ui` — React UI layer work
- `runtime-client` — Traverse runtime client boundary work
- `quality` — code quality, coverage, or CI gate work
- `documentation` — docs-only work

Use an `agent:*` label when claimed by an agent. Registered labels: `agent:claude`, `agent:codex`, `agent:cursor`, `agent:antigravity`, `agent:continue`. See `AGENTS.md` Agent Registry.

Use Project 2 status for availability:

- `Ready` — approved and not started yet
- `In Progress` — currently being worked on
- `Blocked` — cannot continue; blocker visible in issue body and Project 2 Note
- `Future` — valid work tracked but intentionally not active now
- `Done` — merged and verified

Do not move work to `In Progress` unless a real dev thread or worker has started it.

## Required Ticket Sections

Every meaningful work ticket should include:

- `Summary`
- `Why`
- `Depends on`
- `Blocked by`
- `Definition of Done`
- `Validation`

## Definition of Done Rule

Definition of done must be specific enough that completion is unambiguous.

State exactly which files, commands, checks, or behaviors must exist when the ticket is done.

Avoid:
- "implement the feature"
- "support the workflow"

Prefer:
- which files or components must exist
- which commands must pass (`npm run typecheck`, `npm run test`, `bash scripts/ci/...`)
- which CI checks must be green
- which runtime events must be handled
- which UI states must be visible (loading, progress, error, final)

### Example — production platform client DoD

Use this shape for embedded platform / runtime-client tickets (Web, Linux/CLI, Android, Windows, Apple):

```markdown
## Definition of Done

- [ ] Production path uses the public platform embedder (embedded mode; no required `traverse-cli serve`)
- [ ] Digest-pinned `runtime/runtime.wasm` synced via the named `scripts/ci/sync_*_bundle.sh` wrapper; pin matches `runtime-release.json` (`docs/runtime-bundle-sync.md`)
- [ ] Unit tests inject SDK doubles only (`EmbedderTestDouble` / `InMemoryTraverseEmbedder`); UI never computes title/tags/note type/next action/status
- [ ] Platform README documents **Runtime mode: Embedded** and sync/build commands
- [ ] Doc touchpoints updated when shipping status changes (`README.md` platform table, `docs/design-language.md` reference row)
- [ ] Validation commands listed and green locally / on CI (`npm` gates and/or `bash scripts/ci/embedded_smoke.sh` for Linux-runnable slices)
```

Docs-only tickets may omit embed/sync/SDK lines but must still name the exact files and the `pr_body_check` / repository-check commands that prove the doc landed.

## Validation Rule

Validation instructions must be concrete and reproducible.

Each ticket should identify:

- exact commands to run
- exact checks expected to pass
- exact outputs or UI states expected to exist

If the ticket is UI-only, validation should confirm no business logic was added.

If the ticket touches the runtime client boundary, validation should confirm only public Traverse interfaces are used.

## Blocked Rule

If a ticket is blocked, the ticket must say why.

Use:
- label: `blocked`
- section: `Blocked by`
- Project 2 `Note` field: short blocker summary visible on the board

Common blockers in this repo:

- depends on a Traverse runtime release (name the feature/CLI command)
- depends on another issue (link it)
- waiting on Enrico decision (use `needs-enrico`)

## Architecture Boundary Rule

Every ticket that touches runtime integration must state:

- which public Traverse interface is used
- that no private Traverse internals are imported
- that no business logic is computed in the UI

## Must-Fix vs Future Rule

When a problem is found during active work:

- if it is required for correctness, governance, or mergeability — fix it in the same PR
- if it is not required — create a `future` ticket instead of silently dropping it

## Merge Candidate Rule

When a ticket's PR is the next candidate to merge:

- do not start unrelated side work ahead of merging
- update the PR to latest base immediately after any prior merge touches `main`
- keep the ticket marked active until the merge finishes
- if the PR is green but behind base, update it immediately
