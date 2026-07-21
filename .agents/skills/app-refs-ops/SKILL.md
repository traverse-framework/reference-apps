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

1. **PR finisher** — inspect open PRs owned by this agent or blocking Ready work; fix CI/review issues; queue `gh pr merge <N> --squash --auto` once fixes are pushed; rebase if behind `main`. Dependabot PRs: `@dependabot rebase` + queue auto-merge, never hand-write their bodies.
2. **Release** — after merge: remove `agent:*` label, set Agent → Unassigned, Status → Done, close issue (see Release sequence below).
3. **Ready-ticket worker** — query Ready items; run pre-flight on the next unclaimed ticket; claim; implement; open PR.
4. **Validate** — run applicable local gates; queue `gh pr merge <N> --squash --auto`; do **not** poll CI — continue to the next Ready ticket and run the release step on a later pass once it has merged.

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

Run the release command sequence from `AGENTS.md` (single copy: remove agent label, Agent → Unassigned, Status → Done, close issue).

## Workflow

1. Read `AGENTS.md` and follow the agent coordination rules.
2. Read the constitution (via `traverse-framework/.github`, pinned in `.governance-version`) only when the ticket touches architecture or contracts — lazy-read map in the org's `docs/ai-agent-hardening.md`.
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
9. Open a dedicated PR using the org body superset (`## Summary`, `## Governing Spec`, `## Project Item`, `## Definition of Done`, `## Validation`).
10. Queue auto-merge, then **return to step 4** for the next Ready ticket; release merged work on the next loop pass.

## Project 2 IDs, Pre-flight & Claim

Field/option IDs, the three pre-flight checks, and the claim/release command sequences live in `AGENTS.md` — the single copy. Never duplicate them here.

## Gates & Failure Playbook

Every PR must pass the org gates `cla / cla` and `baseline / governance-baseline` plus this repo's CI (`pr-hygiene` checks the body sections). When a governance gate fails, use the failure playbook in `traverse-framework/.github` `docs/runbook.md` (CLA `recheck` comment; re-runs pin stale gate snapshots, push a commit instead).

### Production-baseline gates (platform / runtime-client PRs)

Before queueing auto-merge on a platform or runtime-client PR, confirm the PR body checklist covers:

1. **Embedded mode** — public in-process embedder; no required `traverse-cli serve` for the shipping path
2. **Digest pin / sync** — followed `docs/runtime-bundle-sync.md`; ran the relevant `scripts/ci/sync_*_bundle.sh`
3. **SDK test doubles** — tests use public doubles only; no business fields invented in app/UI code
4. **Docs touchpoints** — platform README Runtime mode + design-language / README shipping rows when status changes
5. **CI commands** — Validation section lists the commands that prove the slice (`npm` gates, `embedded_smoke`, platform build)

Docs-only PRs still need `## Summary` / `## Definition of Done` / `## Validation` but may mark production-baseline items N/A with a one-line reason.

Dependabot PRs: `@dependabot rebase` + queue auto-merge; never hand-write their bodies. If `pr-hygiene` fails on Dependabot, fix the gate exemption in a dedicated ops ticket — do not paste template sections into Dependabot descriptions.

## Token Discipline

Org-canon token rules live in `traverse-framework/.github` `docs/ai-agent-hardening.md`
(pinned via `.governance-version`): bounded `--limit` queries with server-side `--jq`,
no raw board/CI/test log dumps, targeted diffs, short progress updates.
Repo-specific addition:

- Never index or read platform build output (see `.claudeignore`); reproduce gate
  failures locally (`npm run test`, `bash scripts/ci/repository_checks.sh`) before
  fetching remote logs.

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
