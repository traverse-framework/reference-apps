# Ticket Standard

This document defines the minimum quality bar for App-References **tickets**.

## Core Rule

**Project 2 is the only backlog.** Tickets are [Project 2](https://github.com/orgs/traverse-framework/projects/2) items (prefer **Draft** items). Do **not** open GitHub Issues to track App-Refs work. Closed issues may remain as historical archive for shipped work; they are not tickets.

Every meaningful ticket must be explicit enough that a developer can tell:

- whether the work is available to start
- whether it is blocked
- what "done" means
- how to validate that it is complete
- whether it touches the UI boundary, the runtime client, or both

## Ticket identity

Each active ticket must include a stable **Ticket ID** slug in the draft body:

```markdown
## Ticket ID
`meeting-notes-multi-os`
```

Use that slug in branch names (`<agent>/ticket-<ticket-id>-*`) and in PR `## Project Item` sections. Do not invent GitHub issue numbers for new work.

## Where Spec and DoD live

| Field | Purpose |
|---|---|
| **Draft body** | Full Spec + Summary / Why / Depends on / Blocked by / Definition of Done / Validation |
| **Project 2 Note** | One-line board summary + `ticket-id: …` |
| **Status** | Availability (`Ready`, `In Progress`, `Blocked`, `Future`, `Done`) |
| **Agent** | Claim lock (`Unassigned` or a registered tool) |

## Project 2 status

- `Ready` — approved and not started yet
- `In Progress` — currently being worked on (Agent must be set)
- `Blocked` — cannot continue; blocker visible in draft body **and** Project 2 Note
- `Future` — valid work tracked but intentionally not active now
- `Done` — merged and verified

Do not move work to `In Progress` unless a real worker has claimed it via the Agent field.

## Required Ticket Sections

Every meaningful work ticket body should include:

- `Ticket ID`
- `Spec` (governing docs / public APIs / architecture boundary)
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

- Project 2 Status → `Blocked`
- section: `Blocked by` in the draft body
- Project 2 `Note` field: short blocker summary visible on the board

Common blockers in this repo:

- depends on a Traverse runtime release (name the feature/CLI command / upstream ticket)
- depends on another Project 2 ticket (cite **Ticket ID**)
- waiting on Enrico decision (set Note + Status; do not open a GitHub issue)

## Architecture Boundary Rule

Every ticket that touches runtime integration must state in **Spec**:

- which public Traverse interface is used
- that no private Traverse internals are imported
- that no business logic is computed in the UI

## Must-Fix vs Future Rule

When a problem is found during active work:

- if it is required for correctness, governance, or mergeability — fix it in the same PR
- if it is not required — create a Project 2 **Future** draft ticket (Spec + DoD) instead of silently dropping it or opening a GitHub issue

## Merge Candidate Rule

When a ticket's PR is the next candidate to merge:

- do not start unrelated side work ahead of merging
- update the PR to latest base immediately after any prior merge touches `main`
- keep the ticket Status `In Progress` until the merge finishes, then set `Done`
- if the PR is green but behind base, update it immediately
