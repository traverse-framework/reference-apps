# App-References Development Guidelines

This repo is **UI-only**. Traverse runtime and business logic live outside this repo.

## Current State

**Repo:** `traverse-framework/reference-apps` | **Board:** [Project 2](https://github.com/orgs/traverse-framework/projects/2)

### Platform clients

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped | `apps/traverse-starter/web-react/` |
| trace-explorer (React) | Shipped | `apps/trace-explorer/web-react/` |
| iOS (SwiftUI) | Blocked ([#44](https://github.com/traverse-framework/reference-apps/issues/44)) | Waiting: [Traverse #525](https://github.com/traverse-framework/Traverse/issues/525), [#526](https://github.com/traverse-framework/Traverse/issues/526), [#527](https://github.com/traverse-framework/Traverse/issues/527) |
| macOS (SwiftUI + AppKit) | Blocked ([#45](https://github.com/traverse-framework/reference-apps/issues/45)) | Same as iOS |
| Android (Jetpack Compose) | Planned | Issue TBD |
| Windows (WinUI 3) | Planned | Issue TBD |
| Linux (GTK4 + Rust) | Planned | Issue TBD |
| CLI (Rust) | Planned | Issue TBD |

### Ready to claim (query live board)

```bash
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.status == "Ready") | {number: .content.number, title: .content.title}'
```

### Blocked work summary

- **Web SSE refactor** ([#43](https://github.com/traverse-framework/reference-apps/issues/43)) — replace polling with runtime SSE; blocked on Traverse #525, #526, #527
- **iOS / macOS clients** ([#44](https://github.com/traverse-framework/reference-apps/issues/44), [#45](https://github.com/traverse-framework/reference-apps/issues/45)) — blocked on Traverse #522, #525+

Update this section when a PR changes platform status (see PR template checklist).

## Project Structure

```text
apps/
  traverse-starter/
    web-react/           # React UI shell
.agents/skills/
  app-refs-ops/          # Ops skill for Project 2 work
.specify/memory/         # Constitution and governing principles
docs/                    # Quality standards, ticket standard, workflow docs
scripts/ci/              # CI gate scripts
.github/workflows/       # GitHub Actions
```

## Traverse Runtime

**Current release: v0.6.0** (recommended for all phases) | Phase 1 minimum: v0.3.0 | Phase 2 minimum: v0.5.0 | API spec: **033-http-json-api** (approved v1.1.0)

```bash
# Start local runtime
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
# Writes .traverse/server.json with base_url=http://127.0.0.1:8787, workspace_default=local-default
```

Discovery in code:
```js
const { base_url, workspace_default } = JSON.parse(fs.readFileSync('.traverse/server.json'))
```

Override: `TRAVERSE_REPO=/path/to/Traverse`

## Commands

```bash
npm install
npm run dev
npm run build
npm run typecheck
npm run lint
npm run test
npm run test:coverage
bash scripts/ci/repository_checks.sh
bash scripts/ci/phase1_smoke.sh
```

## Code Style

- No business logic in the React layer
- No private Traverse internals imported
- No fake runtime behavior
- Full unit test coverage for non-trivial UI logic

## Lean Implementation

Before adding code:

1. Does this change need to exist for the active issue?
2. Does it belong in the UI layer at all, or in Traverse?
3. Can existing components, hooks, or config already satisfy it?
4. Can a type, config, or doc update solve it without a new abstraction?
5. Can one focused component or hook solve it?
6. Add only the minimum new structure needed.

Minimality must never push business logic into the UI or import private Traverse internals.

<!-- MANUAL ADDITIONS START -->
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
gh issue view <NUMBER> --repo traverse-framework/App-References --json labels \
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
gh issue edit <NUMBER> --repo traverse-framework/App-References --add-label "<AGENT_LABEL>"

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
gh issue edit <NUMBER> --repo traverse-framework/App-References --remove-label "<AGENT_LABEL>"

# Set Agent → Unassigned, Status → Done
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik --single-select-option-id 8ebf043b
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz --id "$ITEM_ID" \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ --single-select-option-id 98236657

# Close the issue
gh issue close <NUMBER> --repo traverse-framework/App-References
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

## Governance

Read `.specify/memory/constitution.md` before any implementation work.

- **UI boundary**: no business logic, no private Traverse internals, no fake runtime behavior
- **Traceability**: all work must have a GitHub issue + Project 2 item + PR
- **Phase 2 is blocked**: do not implement app registration until Traverse CLI surface exists
<!-- MANUAL ADDITIONS END -->
