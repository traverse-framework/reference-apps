---
name: "app-refs-ops"
description: "Start or resume the App-References operating model when the user says APP REFS OPS, asks to start app-refs ops/dev work, asks for the ready-ticket worker, PR finisher, or backlog gardener, or wants Codex to pick ready Project 2 work and run the App-References coordination process."
---

# App-References Ops

Use this skill when the user wants Codex to start or resume the standard App-References operating model.

Canonical trigger:

```text
APP REFS OPS
```

## Context

This repo is **UI-only**. Traverse runtime and business logic live outside this repo.
The UI must not compute business fields (tags, note type, next action, status) — it renders runtime-provided data only.

All tickets live in [Project 2](https://github.com/orgs/traverse-framework/projects/2) (`traverse-framework`, project number `2`).
The target repo is `traverse-framework/App-References`.

Read `docs/traverse-starter-plan.md` and `.specify/memory/constitution.md` before any implementation work.

## Workflow

1. Read `.specify/memory/constitution.md` before any implementation work.
2. Read `AGENTS.md` and follow the agent coordination rules.
3. Inspect current GitHub and Project 2 state.
4. Prefer finishing existing open PRs before claiming new Ready work.
5. If no active PR needs attention, pick one Ready Project 2 issue.
6. Before work on an issue, run the pre-flight checks from `AGENTS.md`:
   - issue must not have `agent:claude`
   - no remote `claude/issue-NNN-*` branch may exist
7. If pre-flight passes, claim the issue:
   - add `agent:codex`
   - set Project 2 `Agent` to `Codex`
   - set Project 2 `Status` to `In Progress`
8. Use a dedicated `codex/issue-NNN-*` branch.
9. Keep work scoped to the claimed issue and the UI-only architecture boundary.
10. Open a dedicated PR with the required sections (Summary, Definition of Done, Validation).

## Project 2 IDs

| Resource | ID |
|---|---|
| Project node ID | `PVT_kwDOEbiBt84BbzAz` |
| Status field | `PVTSSF_lADOEbiBt84BbzAzzhWg5OQ` |
| Status: Todo | `f75ad846` |
| Status: In Progress | `47fc9ee4` |
| Status: Done | `98236657` |
| Status: Ready | `81742589` |
| Status: Blocked | `559e1fec` |
| Status: Future | `7130dc35` |
| Agent field | `PVTSSF_lADOEbiBt84BbzAzzhWjEik` |
| Agent: Unassigned | `8ebf043b` |
| Agent: Codex | `e428b05e` |
| Agent: Claude Code | `8f903ad6` |
| Agent: Cursor | `a9811389` |
| Agent: Antigravity | `77295899` |
| Note field | `PVTF_lADOEbiBt84BbzAzzhWjEio` |

## Pre-flight + Claim Sequence

Multiple agents run in parallel. All three checks must pass before claiming.

```bash
# Check 1 — any agent:* label already on this issue?
gh issue view <NUMBER> --repo traverse-framework/App-References --json labels \
  --jq '.labels[].name | select(startswith("agent:"))'
# If anything is returned → STOP. Issue is already claimed.

# Check 2 — any agent branch already exists?
git ls-remote --heads origin | grep "/issue-<NUMBER>-"
# If anything is returned → STOP. Another agent is already working this.

# Check 3 — status is Ready?
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.content.number == <NUMBER>) | .status'
# If not "Ready" → STOP.

# ── All three passed — now claim ──────────────────────────────────────────

gh issue edit <NUMBER> --repo traverse-framework/App-References --add-label "agent:codex"

ITEM_ID=$(gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.content.number == <NUMBER>) | .id')

gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik \
  --single-select-option-id e428b05e   # Codex

gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ \
  --single-select-option-id 47fc9ee4   # In Progress
```

## Token Discipline

- Prefer targeted GitHub queries over full board dumps. For Ready work:
  ```bash
  gh project item-list 2 --owner traverse-framework --format json --limit 300 \
    --jq '.items[] | select(.status == "Ready") | {number: .content.number, title: .content.title}'
  ```
- Do not paste full project lists, test output, or CI logs. Summarize pass/fail and quote only failing lines.
- Use `git diff --stat` and focused file hunks before large diffs.
- Keep progress updates short: current action, any blocker, next action.

## Minimality Ladder

Before adding code:

1. Does this change need to exist for the active issue?
2. Does it belong in the UI layer at all, or in Traverse?
3. Can existing components, hooks, or config already satisfy it?
4. Can a type, config, or doc update solve it without a new abstraction?
5. Can one focused component or hook solve it?
6. Add only the minimum new structure needed.

Minimality must never push business logic into the UI, import private Traverse internals, or fake runtime behavior.

## Architecture Guardrails

- **Never** compute title, tags, note type, next action, or status in the UI
- **Never** import private Traverse internals
- **Never** fake workflow registration or runtime behavior in application code
- **Always** drive UI state from runtime-provided events
- Phase 2 (app validation/registration) is **blocked** until Traverse public CLI surface exists

## Operating Lanes

- **Ready-ticket worker**: claim one Ready Project 2 issue and implement it end to end.
- **PR finisher**: inspect open PRs, fix CI/review issues, and merge when green.
- **Backlog gardener**: audit Project 2 statuses, labels, blockers, and notes.

## Guardrails

- Do not mark work `In Progress` unless a real dev thread has started.
- Do not use labels as status; Project 2 status is the actionability source of truth.
- Do not claim work already owned by Claude Code.
- Do not broaden scope beyond the issue and the UI-only architecture boundary.
- Create follow-up tickets for non-blocking improvements instead of expanding an active slice.

For the full operating model, see `docs/multi-thread-workflow.md`.
