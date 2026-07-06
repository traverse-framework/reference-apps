---
name: "app-refs-ops"
description: "Start or resume the App-References operating model when the user says APP REFS OPS. Runs continuously until no Ready work remains or a hard blocker stops progress — merge green PRs, claim Ready tickets, implement, release, repeat."
---

# App-References Ops

Use this skill when the user wants Codex to start or resume the standard App-References operating model.

Canonical trigger:

```text
APP REFS OPS
```

## Context

This repo is **UI-only**. Business logic lives in Traverse WASM agents. **Phase 3 target:** embedded runtime in every platform app. Phase 1/2 HTTP sidecar is dev-only interim.

All tickets live in [Project 2](https://github.com/orgs/traverse-framework/projects/2) (`traverse-framework`, project number `2`).
The target repo is `traverse-framework/reference-apps` (GitHub slug; product name App-References).

Read `docs/embedded-runtime-plan.md`, `docs/traverse-starter-plan.md`, and `.specify/memory/constitution.md` before any implementation work.

## Continuous run mode (default)

`/app-refs-ops` is **not** a single-ticket session. When triggered, run the full ops loop **until idle** — do not stop after one PR, one merge, or one status summary, and do not ask the user "want me to continue?" between tickets.

### Ops loop

Repeat until a stop condition (below):

1. **PR finisher** — inspect open PRs owned by this agent or blocking Ready work; fix CI/review issues; merge when green; rebase if behind `main`.
2. **Release** — after merge: remove `agent:*` label, set Agent → Unassigned, Status → Done, close issue (see Release sequence below).
3. **Ready-ticket worker** — query Ready items; run pre-flight on the next unclaimed ticket; claim; implement; open PR.
4. **Validate** — run applicable local gates; wait for CI; merge when green; go to step 2.

One issue at a time per agent thread, but **many issues per ops invocation** — keep cycling.

### Stop conditions (only these)

Stop reporting only when **all** are true:

- No open PRs from this ops run need attention (merged or explicitly handed off).
- No Project 2 items remain in `Ready` that pass pre-flight for this agent.
- No fixable CI failures on open PRs you opened this session.

**Do not stop** merely because one ticket shipped. **Do not pause** for merge approval if CI is green and the user invoked `/app-refs-ops` for autonomous end-to-end execution — merge and continue.

### When to ask the user

Ask only for:

- Product or architecture decisions (`needs-enrico`)
- Merge approval if the user explicitly said not to merge autonomously in this session
- Hard blockers outside this repo (Traverse runtime feature missing, credentials, environment)

Everything else — claim, implement, PR, CI fix, merge, release — proceed autonomously.

### Release sequence (after merge)

```bash
gh issue edit <NUMBER> --repo traverse-framework/reference-apps --remove-label "<AGENT_LABEL>"

ITEM_ID=$(gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.content.number == <NUMBER>) | .id')

gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik --single-select-option-id 8ebf043b

gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ --single-select-option-id 98236657

gh issue close <NUMBER> --repo traverse-framework/reference-apps
```

## Workflow

1. Read `.specify/memory/constitution.md` before any implementation work.
2. Read `AGENTS.md` and follow the agent coordination rules.
3. Inspect current GitHub and Project 2 state.
4. Enter the **ops loop** above — do not exit after step 10 once; loop until idle.
5. Before work on an issue, run the pre-flight checks from `AGENTS.md`:
   - issue must not have any `agent:*` label
   - no remote `*/issue-NNN-*` branch may exist
   - Project 2 status must be `Ready`
6. If pre-flight passes, claim the issue:
   - add your agent label (see Agent Registry in `AGENTS.md`)
   - set Project 2 `Agent` to your tool
   - set Project 2 `Status` to `In Progress`
7. Use a dedicated `<agent>/issue-NNN-*` branch (see Agent Registry in `AGENTS.md`).
8. Keep work scoped to the claimed issue and the UI-only architecture boundary.
9. Open a dedicated PR with the required sections (Summary, Definition of Done, Validation).
10. Validate, merge when green, release, then **return to step 4** for the next Ready ticket.

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
| Agent: Continue | `156c534e` |
| Note field | `PVTF_lADOEbiBt84BbzAzzhWjEio` |

## Pre-flight + Claim Sequence

Multiple agents run in parallel. All three checks must pass before claiming.

```bash
# Check 1 — any agent:* label already on this issue?
gh issue view <NUMBER> --repo traverse-framework/reference-apps --json labels \
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

gh issue edit <NUMBER> --repo traverse-framework/reference-apps --add-label "<AGENT_LABEL>"

ITEM_ID=$(gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.content.number == <NUMBER>) | .id')

gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik \
  --single-select-option-id <AGENT_OPTION_ID>

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
- Phase 3 (embedded in-app runtime) is the production target — see `docs/embedded-runtime-plan.md`
- Phase 2 (app validation/registration) uses Traverse CLI against dev sidecar
- Phase 1 HTTP sidecar is **not** the shipping architecture

## Operating Lanes

All lanes run inside the **continuous ops loop** — none of them end the session after one pass.

- **PR finisher**: inspect open PRs, fix CI/review issues, merge when green, release linked issues — then pick the next Ready ticket.
- **Ready-ticket worker**: claim one Ready issue, implement end to end, merge, release — then claim the next Ready issue.
- **Backlog gardener**: audit Project 2 statuses, labels, blockers, and notes — only when no Ready work is available or as hygiene between tickets.

## Guardrails

- Do not mark work `In Progress` unless a real dev thread has started.
- Do not use labels as status; Project 2 status is the actionability source of truth.
- Do not claim work already owned by another agent.
- Do not broaden scope beyond the issue and the UI-only architecture boundary.
- Create follow-up tickets for non-blocking improvements instead of expanding an active slice.
- **Do not stop the ops loop after one ticket** — run until Ready queue is empty or a stop condition applies.
- **Do not ask the user to continue** between tickets during `/app-refs-ops`; that breaks autonomous end-to-end execution.

For the full operating model, see `docs/multi-thread-workflow.md`.
