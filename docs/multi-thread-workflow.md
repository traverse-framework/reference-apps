# Multi-Thread Workflow

App-References supports parallel execution when parallel work is real.

One dev thread is one active worker. For true parallel work, run multiple dev threads — each with a separate issue, branch, and PR.

## Multi-Agent Model

Multiple coding agents (Codex, Claude Code, Cursor, Antigravity, Continue, and others) can work in parallel on separate issues. To prevent conflicts:

- **Labels**: `agent:*` marks which agent owns an issue (see Agent Registry in `AGENTS.md`)
- **Project board**: the Agent field shows ownership at a glance
- **Branches**: `<agent>/issue-NNN-*` naming makes branch ownership explicit (e.g. `cursor/issue-84-*`, `codex/issue-84-*`)

**Rule**: claim before you code. Every agent checks for any existing `agent:*` label and any remote `*/issue-NNN-*` branch before starting work. See `AGENTS.md` for the full pre-flight sequence.

## Thread Roles

### PM Thread

The PM thread:

- keeps the backlog, labels, blockers, and Project 2 current
- talks with Enrico about product and architecture decisions
- decides when work is `Ready`, `Blocked`, `In Progress`, or `Future`
- does not mark a ticket `In Progress` unless a real worker has started

### Dev Threads

Each dev thread:

- owns exactly one active issue at a time
- works on exactly one branch at a time
- opens exactly one PR for that slice
- keeps work within the UI-only architecture boundary

One dev thread per issue. If two issues touch the same components heavily, do not start them in parallel.

### Review Thread

The review thread:

- checks architecture boundary alignment (no business logic, no private Traverse internals)
- checks for missing tests or coverage gaps
- checks merge conflicts and integration risk
- ensures must-fix findings are fixed in the active PR
- turns non-blocking follow-up work into `future` tickets

## Status Rules

- `Ready` — approved and available to start
- `In Progress` — a real dev thread is actively working the ticket
- `Blocked` — cannot continue; blocker visible in issue body and Project 2 Note
- `Future` — valid work tracked but intentionally not active now
- `Done` — merged and verified

Do not move work to `In Progress` merely because it is a candidate for parallel execution.

If a ticket has an open PR, it must be `In Progress` on Project 2. Fix mismatches immediately.

## Parallel Work Rules

For parallel work to be valid:

- each active issue must have a dedicated dev thread
- each active issue must have its own branch
- each active issue must have its own PR
- Project 2 `Status` must match reality
- Project 2 `Note` should identify the worker or workstream when useful

## Chat Trigger

Use this short trigger when you want Codex to start or resume the App-References operating model:

```text
APP REFS OPS
```

When Enrico says `APP REFS OPS`, Codex should:

- Start or resume the **ready-ticket worker**: pick one Ready Project 2 ticket, follow `AGENTS.md`, claim it, set `In Progress`, implement on one branch, open one PR.
- Start or resume the **PR finisher**: inspect open PRs, fix CI/review issues, merge green PRs, update linked issues and Project 2 state.
- Start or resume the **backlog gardener**: audit Project 2 statuses, labels, blockers, and notes; ensure items have the right status; create missing tickets with full Definition of Done.
- Do all feasible work autonomously. Ask only when a product or architecture decision requires Enrico.
- Run lean: filtered Project 2 queries, bounded command output, focused diffs, summarized CI results.

## Starter Prompts

### PM Thread

```text
Act as the App-References PM thread.
Keep GitHub issues, Project 2, labels, blockers, notes, and PR flow accurate.
Do not mark a ticket In Progress unless a real dev thread has started it.
When a problem is must-fix for the active slice, it must be fixed in the active PR.
When a problem is non-blocking, create a future ticket.
Keep all work within the UI-only architecture boundary.
```

### Dev Thread

```text
Act as an App-References dev thread for issue #NN.

Pre-flight (run before any work):
1. gh issue view NN --repo traverse-framework/reference-apps --json labels \
     --jq '.labels[].name | select(startswith("agent:"))'
   If any `agent:*` label is returned → STOP. Report which agent owns the issue.
2. git ls-remote --heads origin | grep "/issue-NN-"
   If any branch matches `*/issue-NN-*` → STOP. Report the existing branch.

Claim (only if pre-flight passes):
1. gh issue edit NN --repo traverse-framework/reference-apps --add-label "<AGENT_LABEL>"
2. Get item ID: gh project item-list 2 --owner traverse-framework --format json --limit 300 \
     --jq '.items[] | select(.content.number == NN) | .id'
3. Set Agent field (see Agent Registry in AGENTS.md for option IDs)
4. Set Status → In Progress:
   gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id <ITEM_ID> \
     --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ --single-select-option-id 47fc9ee4

Then proceed:
- Only work on this issue
- Use a dedicated <agent>/issue-NN-* branch and open a dedicated PR
- Keep implementation within the UI-only architecture boundary
- No business logic in the UI layer
- No private Traverse internals imported
- If you find a must-fix issue, fix it in the same PR
- If you find a non-blocking improvement, create a future ticket
```

### Review Thread

```text
Act as the App-References review thread.
Review active PRs for architecture boundary violations (business logic in UI, private Traverse internals),
missing tests, coverage gaps, merge risk, and governance gaps.
Must-fix findings stay in the active PR.
Non-blocking follow-ups become future tickets.
Keep the repo and board consistent with the approved process.
```
