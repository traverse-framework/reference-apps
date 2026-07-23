# App-References — Agent Coordination

This repo is **UI-only**; canonical agent instructions (scope, structure, stack, commands, style, runtime setup, workflow) live in [CLAUDE.md](CLAUDE.md). This file holds only multi-tool coordination and curated blocker context, per `traverse-framework/.github` `docs/ai-agent-hardening.md`. Platform shipping status lives in README.md and on [Project 2](https://github.com/orgs/traverse-framework/projects/2) — never snapshot it here.

**Backlog rule:** tickets live **only** on Project 2 (Draft items with Spec + DoD). Do not open GitHub Issues to track work. See [`docs/ticket-standard.md`](docs/ticket-standard.md).

### Ready to claim (query live board)

```bash
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.status == "Ready") | {id, title: (.title // .content.title), note, agent}'
```

### Start plan (demo gaps → tickets)

| Ticket ID | Status | Start |
|---|---|---|
| `remove-sidecar-paths` | **Done** (#206) | Sidecar paths removed from primary shells |
| `meeting-notes-multi-os` | **Done** (#208) | Web + Linux GTK + CLI embedded |
| `native-ci-android-gtk-required` | **Done** (#209) | Android/GTK nightly required |
| `phase2-sidecar-nightly` | Future | Defer — low demo value |
| `embed-trace-explorer` | **Done** (#225) | Embedded Trace API in Trace Explorer web |
| `registry-ref-starter-process` | **Done** (#224) | Process component uses `registry_ref` |
| `consume-product-wasm-agents` | **Done** (#227) | Digest-pinned Traverse-published starter agents |

Full gap table + wave notes: [`docs/production-reference-plan.md`](docs/production-reference-plan.md).

### Flip rules (native embeds)

Upstream flip conditions are met (Traverse #750/#751/#647 closed). Embeds are **Done**. Return any platform to Blocked only if Traverse withdraws the certified `runtime/runtime.wasm` artifact or reopens those upstream issues.

## Multi-Agent Coordination

Multiple LLM coding tools work in parallel on this repo: Codex, Claude Code, Cursor, Antigravity, and others.

**The golden rule: claim before you code. One Project 2 ticket = one agent.**

If you find a ticket already claimed (Agent ≠ Unassigned), stop immediately and pick a different ticket.
Do not attempt to "help" a claimed ticket or work around an existing claim.

---

## Pre-flight Protocol (ALL agents must follow this)

Run these three checks **before starting any work on a ticket**. All three must pass.

Identify the ticket by **Ticket ID** (from draft body / Note) and Project 2 `ITEM_ID`.

### Check 1 — Agent is Unassigned

```bash
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select((.title // .content.title) | test("<TITLE_OR_TICKET_ID>"; "i")) | {id, agent, status, note}'
```

**If Agent is set to another tool → STOP.**

Report: `Ticket <ticket-id> is already claimed by <agent>. Choose a different ticket.`

### Check 2 — No existing agent branch

```bash
git ls-remote --heads origin | grep "/ticket-<TICKET_ID>-"
```

**If any branch matches `*/ticket-<TICKET_ID>-*` → STOP.**

Report: `A branch already exists for ticket <TICKET_ID>: <branch>. Choose a different ticket.`

### Check 3 — Status is Ready

```bash
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.id == "<ITEM_ID>") | .status'
```

**If status is not `Ready` → STOP.**

Report: `Ticket <ticket-id> has status <status>, not Ready. Choose a different ticket.`

---

## Claim Sequence (only if all three checks pass)

Replace `<AGENT_OPTION_ID>` with your Agent field option ID from the registry below.

```bash
ITEM_ID="<PROJECT_ITEM_ID>"

# 1. Set Agent field
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik \
  --single-select-option-id <AGENT_OPTION_ID>

# 2. Set Status → In Progress
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ \
  --single-select-option-id 47fc9ee4
```

Use branch: `<prefix>/ticket-<TICKET_ID>-*` (see Agent Registry).

## Agent Registry

| Tool | Branch prefix | Agent field option ID |
|---|---|---|
| Claude Code | `claude/ticket-<id>-*` | `8f903ad6` |
| Codex | `codex/ticket-<id>-*` | `e428b05e` |
| Cursor | `cursor/ticket-<id>-*` | `a9811389` |
| Antigravity | `antigravity/ticket-<id>-*` | `77295899` |
| Continue | `continue/ticket-<id>-*` | `156c534e` |

To register a new tool: add its Agent field option (update Project 2 via GraphQL) and add a row to this table. Optional `agent:*` GitHub labels are legacy and not required for claim.

## Release Sequence

After your work is merged:

```bash
# Set Agent → Unassigned, Status → Done
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik --single-select-option-id 8ebf043b
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ --single-select-option-id 98236657
```

Do **not** open or close GitHub Issues for ticket lifecycle.

## Board hygiene

When a platform client (or other major slice) ships, update all doc touchpoints in one pass:

1. **Project 2** — set Status → Done; set Agent → Unassigned
2. **`AGENTS.md`** — update the Blocked/Future summary if applicable (platform status lives in README.md only)
3. **`README.md`** — update the Platform clients table; remove from **What's Blocked** if no longer blocked; add new blockers only when status is Blocked on Project 2
4. **`docs/design-language.md`** — add or update the row in the Reference implementation table

Do not leave shipped platforms listed as "in progress" or "blocked" in any doc.

## Creating tickets

```bash
# Draft ticket (body = full Spec + DoD per docs/ticket-standard.md)
gh api graphql -f query='
mutation($projectId: ID!, $title: String!, $body: String!) {
  addProjectV2DraftIssue(input: {projectId: $projectId, title: $title, body: $body}) {
    projectItem { id }
  }
}' -f projectId='PVT_kwDOEbiBt84BbzAz' -f title='...' -f body='...'

# Then set Status + Note (ticket-id: …) + Agent Unassigned via gh project item-edit
```

## Project 2 Field IDs

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
