# Multi-Thread Workflow

App-References supports parallel execution when parallel work is real.

One dev thread is one active worker. For true parallel work, run multiple dev threads — each with a separate **Project 2 ticket**, branch, and PR.

## Multi-Agent Model

Multiple coding agents (Codex, Claude Code, Cursor, Antigravity, Continue, and others) can work in parallel on separate tickets. To prevent conflicts:

- **Project board**: the Agent field is the claim lock
- **Branches**: `<agent>/ticket-<ticket-id>-*` naming makes branch ownership explicit
- **Backlog**: Project 2 Draft tickets only — no GitHub Issues for tracking

**Rule**: claim before you code. Every agent checks Project 2 Agent ≠ Unassigned and any remote `*/ticket-<ticket-id>-*` branch before starting work. See `AGENTS.md` for the full pre-flight sequence.

## Thread Roles

### PM Thread

The PM thread:

- keeps the Project 2 backlog, blockers, and Notes current (Draft tickets with Spec + DoD)
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

When Enrico says `APP REFS OPS`, the agent should run the **continuous ops loop** (see `.agents/skills/app-refs-ops/SKILL.md`) until idle:

- **PR finisher** → merge green PRs, release linked issues
- **Ready-ticket worker** → claim, implement, PR, merge, release — then pick the next Ready ticket
- **Backlog gardener** → only when no Ready work is available

Do **not** stop after one ticket or ask to continue between tickets. Ask only for product/architecture decisions or hard external blockers.

Run lean: filtered Project 2 queries, bounded command output, focused diffs, summarized CI results.

## Starter Prompts

### PM Thread

```text
Act as the App-References PM thread.
Keep Project 2 tickets (Draft Spec + DoD), blockers, notes, and PR flow accurate.
Do not open GitHub Issues for backlog tracking.
Do not mark a ticket In Progress unless a real dev thread has started it.
When a problem is must-fix for the active slice, it must be fixed in the active PR.
When a problem is non-blocking, create a Future Project 2 draft ticket.
Keep all work within the UI-only architecture boundary.
```

### Dev Thread

```text
Act as an App-References dev thread for Project 2 ticket <TICKET_ID>.

Pre-flight (run before any work) — see AGENTS.md:
1. Agent field must be Unassigned
2. No remote */ticket-<TICKET_ID>-* branch
3. Status must be Ready

Claim via Project 2 Agent + Status → In Progress only.
Use branch <agent>/ticket-<TICKET_ID>-* and open a dedicated PR.
Cite Ticket ID under ## Project Item.
Keep implementation within the UI-only architecture boundary.
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
