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

See `docs/traverse-starter-plan.md` for the full plan, architecture boundary, phase breakdown, and open questions.

## Workflow

1. Read `docs/traverse-starter-plan.md` before any implementation work.
2. Inspect current GitHub and Project 2 state.
3. Prefer finishing existing open PRs before claiming new Ready work.
4. If no active PR needs attention, pick one Ready Project 2 issue.
5. Before work on an issue, run the pre-flight checks below.
6. If pre-flight passes, claim the issue:
   - Add label `agent:codex`
   - Set Project 2 `Status` to `In Progress`
7. Use a dedicated `codex/issue-NNN-*` branch.
8. Keep work scoped to the claimed issue and the architecture boundary.
9. Open a dedicated PR with validation evidence.

## Pre-flight Checks

Before starting work on an issue, verify it is not already claimed:

### 1. Check for Claude Code claim

```bash
gh issue view <NUMBER> --repo traverse-framework/App-References --json labels
```

If labels include `agent:claude` → **STOP**. Report:
> Issue #\<NUMBER\> is claimed by Claude Code. Choose a different ticket.

### 2. Check for Claude Code branch

```bash
git ls-remote --heads origin | grep "issue-<NUMBER>-"
```

If a `claude/issue-<NUMBER>-*` branch exists → **STOP**. Report:
> A Claude Code branch exists for issue #\<NUMBER\>. Choose a different ticket.

If both checks pass → proceed.

## Token Discipline

- Prefer targeted GitHub queries over full board dumps. For Ready work, use:
  ```bash
  gh project item-list 2 --owner traverse-framework --format json --limit 300 \
    --jq '.items[] | {number: .content.number, title: .content.title, status: .status}'
  ```
  Return only issue number, title, status, and labels.
- Do not paste full project item lists, test output, or CI logs. Summarize pass/fail and quote only the failing lines needed to fix the issue.
- Use `git diff --stat` and focused file hunks before large diffs.
- Keep progress updates short: current action, any blocker, next action.
- After CI starts, poll with bounded output; report only changed status.

## Minimality Ladder

Before adding code to this UI repo:

1. Does this change need to exist for the active issue?
2. Can existing component structure, config, or docs already satisfy it?
3. Can the React/browser platform or an existing dependency do it?
4. Can a config update, type, or doc change solve it without a new abstraction?
5. Can one focused component, hook, or config field solve it?
6. Only then add the minimum new structure needed.

Minimality must never push business logic into the UI, import private Traverse internals, or fake runtime behavior.

## Architecture Guardrails

- **Never** compute title, tags, note type, next action, or status in the UI.
- **Never** import private Traverse internals.
- **Never** fake workflow registration or runtime behavior.
- **Always** drive UI state from runtime-provided events.
- Phase 2 work (app validation/registration) is **blocked** until the Traverse public CLI surface exists. Do not unblock it prematurely.

## Operating Lanes

- **Ready-ticket worker**: claim one Ready Project 2 issue and implement it end to end.
- **PR finisher**: inspect open PRs, fix CI/review issues, and merge when green.
- **Backlog gardener**: audit Project 2 statuses, labels, blockers, and open questions in `docs/traverse-starter-plan.md`.

## Guardrails

- Do not mark work `In Progress` unless a real dev thread has started.
- Do not use labels as status; Project 2 status is the actionability source of truth.
- Do not claim work already owned by Claude Code.
- Do not broaden scope beyond the issue and the UI-only architecture boundary.
- Create follow-up tickets for non-blocking improvements instead of expanding an active slice.
- Do not introduce any Traverse runtime business logic into this repo.
