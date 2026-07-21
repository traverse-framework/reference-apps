# App-References Development Guidelines

## Repo Purpose

This repo is **UI-only**. Business logic and WASM agents live in Traverse. **Phase 3 target:** each platform app embeds the WASM runtime host. Phase 1/2 dev uses an HTTP sidecar until migration completes.

See `docs/traverse-starter-plan.md` for the full plan and architecture boundary.

## Project Structure

```text
apps/
  traverse-starter/
    web-react/           # React UI shell for the traverse-starter reference app
    ios-swift/           # SwiftUI iOS client
    macos-swift/         # SwiftUI macOS client
    android-compose/     # Jetpack Compose Android client
    windows-winui/       # WinUI 3 Windows client
    linux-gtk/           # GTK4 + Rust Linux client
    cli-rust/            # Rust CLI client
  doc-approval/          # doc-approval clients (all platforms)
  meeting-notes/         # meeting-notes clients
  trace-explorer/
    web-react/           # Trace Explorer — execution timeline debugger
  react-demo/            # Expedition React browser demo (adopted from Traverse)
  browser-consumer/      # Browser consumer façade
  android-demo/          # Expedition Android demo
  macos-demo/            # Expedition macOS demo
  youaskm3-starter-kit/  # Downstream browser starter kit
fixtures/                # Shared UI demo fixtures
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
bash scripts/ci/embedded_smoke.sh      # Phase 3 embedded smoke (set TRAVERSE_REPO)
bash scripts/ci/phase1_smoke.sh        # Phase 1 end-to-end smoke (sidecar)
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
2. Every meaningful feature requires a Project 2 ticket (Spec + DoD) + PR — no GitHub Issues backlog
3. CI gates must pass before merge: lint, typecheck, tests, coverage, PR hygiene
4. Phase 2 work (app registration) is blocked until the Traverse CLI surface exists

## Project 2 IDs (for agent tooling)

Field/option IDs for board automation live in [AGENTS.md](AGENTS.md) — single copy, never duplicate them here.

## Traverse Runtime

| Detail | Value |
|---|---|
| **Production target (Phase 3)** | Embedded in-app WASM runtime host in every platform client |
| Dev sidecar (Phase 1/2 interim) | **v0.6.0** — `cargo run -p traverse-cli -- serve` @ `127.0.0.1:8787` |
| Phase 1 minimum | v0.3.0 — HTTP/JSON API |
| Phase 2 minimum | v0.5.0 — CLI app validate/register |
| Default workspace | `local-default` |
| Governing API spec (dev sidecar) | `033-http-json-api` (approved v1.1.0) |
| Phase 3 plan | `docs/embedded-runtime-plan.md` |

Dev sidecar setup (interim):
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
2. Claim a Ready Project 2 ticket — see `AGENTS.md` for pre-flight checks
3. Implement the smallest change that satisfies the ticket and architecture boundary
4. Open a PR with the required sections (see `docs/ticket-standard.md`)
5. Verify all CI gates pass before requesting merge

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
