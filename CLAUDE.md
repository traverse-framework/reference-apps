# App-References Development Guidelines

## Repo Purpose

This repo is **UI-only**. Traverse runtime and business logic live outside this repo.
The React UI must not compute business fields — it renders, sorts, filters, and displays
data provided by the Traverse runtime.

See `docs/traverse-starter-plan.md` for the full plan and architecture boundary.

## Project Structure

```text
apps/
  traverse-starter/
    web-react/           # React UI shell for the traverse-starter reference app
.agents/skills/
  app-refs-ops/          # Ops skill for executing Project 2 tickets
.specify/memory/         # Constitution and governing principles
docs/                    # Quality standards, ticket standard, workflow docs
scripts/ci/              # CI gate scripts
.github/workflows/       # GitHub Actions
```

## Stack

- React 18+
- TypeScript
- Vite (or equivalent bundler)
- Vitest (unit tests)
- ESLint + Prettier

## Commands

```bash
npm install              # Install dependencies
npm run dev              # Start local dev server
npm run build            # Production build
npm run typecheck        # TypeScript type check
npm run lint             # ESLint
npm run test             # Run unit tests
npm run test:coverage    # Run tests with coverage
bash scripts/ci/repository_checks.sh   # Repo structure gate
bash scripts/ci/pr_body_check.sh       # PR body validation
bash scripts/ci/coverage_gate.sh       # Coverage gate
bash scripts/ci/phase1_smoke.sh        # Phase 1 end-to-end smoke
```

## Code Style

- No business logic in the UI layer — runtime provides all structured output
- No private Traverse internals imported
- No fake workflow registration or runtime behavior
- Deterministic: same runtime inputs must produce same rendered output
- Full unit test coverage for any non-trivial UI logic (event parsing, state machine)

## Governance

Read `.specify/memory/constitution.md` before any implementation work. Key rules:

1. UI is a rendering layer — all business decisions come from the Traverse runtime
2. Every meaningful feature requires a tracked issue + Project 2 item + PR
3. CI gates must pass before merge: lint, typecheck, tests, coverage, PR hygiene
4. Phase 2 work (app registration) is blocked until the Traverse CLI surface exists

## Project 2 IDs (for agent tooling)

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

## Traverse Runtime

| Detail | Value |
|---|---|
| Current release | **v0.6.0** (recommended checkout for all phases) |
| Phase 1 minimum | v0.3.0 — HTTP/JSON API |
| Phase 2 minimum | v0.5.0 — CLI app validate/register |
| Start runtime | `cargo run -p traverse-cli -- serve` |
| Default address | `127.0.0.1:8787` |
| Discovery file | `.traverse/server.json` |
| Default workspace | `local-default` |
| Governing API spec | `033-http-json-api` (approved v1.1.0) |

Local setup:
```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
# Reads .traverse/server.json for base_url and workspace_default
```

Override for active framework development:
```bash
TRAVERSE_REPO=/path/to/Traverse
cd $TRAVERSE_REPO && cargo run -p traverse-cli -- serve
```

## Development Workflow

1. Clarify whether the change belongs in the UI layer (if not, it belongs in Traverse)
2. Claim a Ready Project 2 issue — see `AGENTS.md` for pre-flight checks
3. Implement the smallest change that satisfies the issue and architecture boundary
4. Open a PR with the required sections (see `docs/ticket-standard.md`)
5. Verify all CI gates pass before requesting merge

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
