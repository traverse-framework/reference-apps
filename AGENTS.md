# App-References — Agent Coordination

This repo is **UI-only**; canonical agent instructions (scope, structure, stack, commands, style, runtime setup, workflow) live in [CLAUDE.md](CLAUDE.md). This file holds only multi-tool coordination and curated blocker context, per `traverse-framework/.github` `docs/ai-agent-hardening.md`. Platform shipping status lives in README.md and on [Project 2](https://github.com/orgs/traverse-framework/projects/2) — never snapshot it here.

### Ready to claim (query live board)

```bash
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.status == "Ready") | {number: .content.number, title: .content.title}'
```

### Blocked work summary

- **Phase 3 embedded runtime** ([#109](https://github.com/traverse-framework/reference-apps/issues/109)–[#118](https://github.com/traverse-framework/reference-apps/issues/118)) — see `docs/embedded-runtime-plan.md`; blocked on a **consumable platform embedder SDK** (Traverse [#553](https://github.com/traverse-framework/Traverse/issues/553) closed via [#578](https://github.com/traverse-framework/Traverse/pull/578) with manifest `execution_mode` only — no web/Swift/etc. embedder package yet)
- **doc-approval multi-capability showcase** ([#111](https://github.com/traverse-framework/reference-apps/issues/111), [#112](https://github.com/traverse-framework/reference-apps/issues/112)) — blocked on Traverse [#538](https://github.com/traverse-framework/Traverse/issues/538) / [#555](https://github.com/traverse-framework/Traverse/issues/555) (`extract` / `recommend` agents)
- **Shared embedded host packages** ([#58](https://github.com/traverse-framework/reference-apps/issues/58), [#59](https://github.com/traverse-framework/reference-apps/issues/59), [#72](https://github.com/traverse-framework/reference-apps/issues/72), [#73](https://github.com/traverse-framework/reference-apps/issues/73)) — Swift/Rust wrappers around embeddable host SDK; blocked on Phase 3 SDK

Ready (not blocked): [#43](https://github.com/traverse-framework/reference-apps/issues/43) web SSE refactor; [#110](https://github.com/traverse-framework/reference-apps/issues/110) traverse-starter.pipeline sidecar path. Native platform SSE upgrades can follow #43.

Update this section when a PR changes platform status (see PR template checklist).

## Multi-Agent Coordination

Multiple LLM coding tools work in parallel on this repo: Codex, Claude Code, Cursor, Antigravity, and others.

**The golden rule: claim before you code. One issue = one agent.**

If you find an issue already claimed, stop immediately and pick a different ticket.
Do not attempt to "help" a claimed ticket or work around an existing claim.

---

## Pre-flight Protocol (ALL agents must follow this)

Run these three checks **before starting any work on an issue**. All three must pass.

### Check 1 — No existing agent label

```bash
gh issue view <NUMBER> --repo traverse-framework/reference-apps --json labels \
  --jq '.labels[].name | select(startswith("agent:"))'
```

**If any `agent:*` label is returned → STOP.**

Report: `Issue #<NUMBER> is already claimed by <label>. Choose a different ticket.`

### Check 2 — No existing agent branch

```bash
git ls-remote --heads origin | grep "/issue-<NUMBER>-"
```

**If any branch matches `*/issue-<NUMBER>-*` → STOP.**

Report: `A branch already exists for issue #<NUMBER>: <branch>. Choose a different ticket.`

### Check 3 — Status is Ready

```bash
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.content.number == <NUMBER>) | .status'
```

**If status is not `Ready` → STOP.**

Report: `Issue #<NUMBER> has status <status>, not Ready. Choose a different ticket.`

---

## Claim Sequence (only if all three checks pass)

Replace `<AGENT_LABEL>` with your tool's label and `<AGENT_OPTION_ID>` with your Agent field option ID.

```bash
# 1. Add your agent label
gh issue edit <NUMBER> --repo traverse-framework/reference-apps --add-label "<AGENT_LABEL>"

# 2. Get the Project 2 item ID for this issue
ITEM_ID=$(gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.content.number == <NUMBER>) | .id')

# 3. Set Agent field
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik \
  --single-select-option-id <AGENT_OPTION_ID>

# 4. Set Status → In Progress
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ \
  --single-select-option-id 47fc9ee4
```

## Agent Registry

| Tool | Label | Branch prefix | Agent field option ID |
|---|---|---|---|
| Claude Code | `agent:claude` | `claude/issue-NNN-*` | `8f903ad6` |
| Codex | `agent:codex` | `codex/issue-NNN-*` | `e428b05e` |
| Cursor | `agent:cursor` | `cursor/issue-NNN-*` | `a9811389` |
| Antigravity | `agent:antigravity` | `antigravity/issue-NNN-*` | `77295899` |
| Continue | `agent:continue` | `continue/issue-NNN-*` | `156c534e` |

To register a new tool: add its label (`gh label create`), add its Agent field option (update Project 2 via GraphQL), and add a row to this table.

## Release Sequence

After your work is merged:

```bash
# Remove your agent label
gh issue edit <NUMBER> --repo traverse-framework/reference-apps --remove-label "<AGENT_LABEL>"

# Set Agent → Unassigned, Status → Done
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik --single-select-option-id 8ebf043b
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ --single-select-option-id 98236657

# Close the issue
gh issue close <NUMBER> --repo traverse-framework/reference-apps
```

## Board hygiene

When a platform client (or other major slice) ships, update all doc touchpoints in one pass:

1. **Project 2** — set Status → Done; set Agent → Unassigned; remove any `agent:*` label
2. **Issue** — close the linked GitHub issue
3. **`AGENTS.md`** — update the Blocked work summary if applicable (platform status lives in README.md only)
4. **`README.md`** — update the Platform clients table; remove from **What's Blocked** if no longer blocked; add new blockers only when status is Blocked on Project 2
5. **`docs/design-language.md`** — add or update the row in the Reference implementation table

Do not leave shipped platforms listed as "in progress" or "blocked" in any doc.

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
