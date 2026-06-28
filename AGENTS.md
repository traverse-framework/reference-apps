# App-References Development Guidelines

This repo is **UI-only**. Traverse runtime and business logic live outside this repo.

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
## Agent Coordination

**Before starting any work on an issue**, run these pre-flight checks:

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

### 3. Claim the ticket (only if pre-flight passes)

```bash
# Add label
gh issue edit <NUMBER> --repo traverse-framework/App-References --add-label "agent:codex"

# Get project item ID
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.content.number == <NUMBER>) | .id'

# Set Agent → Codex
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id <ITEM_ID> \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWjEik \
  --single-select-option-id e428b05e

# Set Status → In Progress
gh project item-edit --project-id PVT_kwDOEbiBt84BbzAz \
  --id <ITEM_ID> \
  --field-id PVTSSF_lADOEbiBt84BbzAzzhWg5OQ \
  --single-select-option-id 47fc9ee4
```

### 4. Governance

Read `.specify/memory/constitution.md` before any implementation work.

- **UI boundary**: no business logic, no private Traverse internals, no fake runtime behavior
- **Traceability**: all work must have a GitHub issue + Project 2 item + PR
- **Phase 2 is blocked**: do not implement app registration until Traverse CLI surface exists
<!-- MANUAL ADDITIONS END -->
