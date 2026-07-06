# Reference Apps

[![CI](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml)

Reference UI applications for the [Traverse](https://github.com/traverse-framework/Traverse) framework.

**Architecture in one sentence:** This repo is UI-only. All business logic runs in the Traverse WASM runtime — the React clients start workflows, subscribe to events, and render runtime-provided output.

## Prerequisites

- **Node.js 24+** (see `.nvmrc`)
- **Rust 1.94+** (to build and run the Traverse runtime)
- **`gh` CLI** (for agents claiming Project 2 tickets)

## Getting Started

```bash
# 1. Clone this repo
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps

# 2. Clone and start the Traverse runtime (separate terminal)
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
# Writes .traverse/server.json → http://127.0.0.1:8787

# 3. Install dependencies
npm install

# 4. Start the traverse-starter dev server
npm run dev
# Opens http://localhost:5173

# 5. In the browser: type a note → Start Workflow → see structured output
```

## What You Will See

The **traverse-starter** UI has three panels:

1. **Runtime Environment** — shows the runtime URL, online/offline status, workspace, and capability ID
2. **Start Workflow** — note input and submit button (disabled when runtime is offline)
3. **Execution Output** — runtime-provided fields: title, tags, note type, suggested next action, status, and trace events

A successful run shows all five output fields populated by the runtime. The UI computes none of them.

## Project Structure

| Path | Purpose |
|---|---|
| [`apps/traverse-starter/web-react/`](apps/traverse-starter/web-react/) | traverse-starter React UI shell |
| [`apps/trace-explorer/web-react/`](apps/trace-explorer/web-react/) | Trace Explorer — execution timeline debugger |
| [`docs/`](docs/) | Plan, runtime setup, quality standards |
| [`manifests/traverse-starter/`](manifests/traverse-starter/) | App manifest + component manifests (Phase 2) |
| [`scripts/ci/`](scripts/ci/) | Repository checks, smoke tests, coverage gate |

## Platform clients

All clients are UI-only shells — they invoke the runtime and render structured output. Phase 1 scaffolds use HTTP polling; SSE upgrade is tracked in [#43](https://github.com/traverse-framework/reference-apps/issues/43).

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped | [`apps/traverse-starter/web-react/`](apps/traverse-starter/web-react/) |
| trace-explorer (React) | Shipped | [`apps/trace-explorer/web-react/`](apps/trace-explorer/web-react/) |
| iOS (SwiftUI) | Shipped | [`apps/traverse-starter/ios-swift/`](apps/traverse-starter/ios-swift/) |
| macOS (SwiftUI + AppKit) | Shipped | [`apps/traverse-starter/macos-swift/`](apps/traverse-starter/macos-swift/) |
| Android (Jetpack Compose) | Shipped | [`apps/traverse-starter/android-compose/`](apps/traverse-starter/android-compose/) |
| Windows (WinUI 3) | Shipped | [`apps/traverse-starter/windows-winui/`](apps/traverse-starter/windows-winui/) |
| Linux (GTK4 + Rust) | Shipped | [`apps/traverse-starter/linux-gtk/`](apps/traverse-starter/linux-gtk/) |
| CLI (Rust) | Shipped | [`apps/traverse-starter/cli-rust/`](apps/traverse-starter/cli-rust/) |

### doc-approval (Phase 1 submitter)

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped | [`apps/doc-approval/web-react/`](apps/doc-approval/web-react/) |
| iOS (SwiftUI) | Shipped | [`apps/doc-approval/ios-swift/`](apps/doc-approval/ios-swift/) |
| macOS (SwiftUI + AppKit) | Shipped | [`apps/doc-approval/macos-swift/`](apps/doc-approval/macos-swift/) |
| Android (Jetpack Compose) | Shipped | [`apps/doc-approval/android-compose/`](apps/doc-approval/android-compose/) |
| Windows (WinUI 3) | Shipped | [`apps/doc-approval/windows-winui/`](apps/doc-approval/windows-winui/) |
| Linux (GTK4 + Rust) | Shipped | [`apps/doc-approval/linux-gtk/`](apps/doc-approval/linux-gtk/) |
| CLI (Rust) | Shipped | [`apps/doc-approval/cli-rust/`](apps/doc-approval/cli-rust/) |

## Development

```bash
npm run dev            # traverse-starter dev server
npm run typecheck
npm run lint
npm run test
bash scripts/ci/repository_checks.sh
bash scripts/ci/phase1_smoke.sh   # requires running runtime
bash scripts/ci/onboarding_check.sh   # local setup verification (runtime steps skip if offline)
```

See [docs/traverse-starter-plan.md](docs/traverse-starter-plan.md) for the full plan and [docs/traverse-runtime.md](docs/traverse-runtime.md) for runtime setup.

## Verify Your Setup

After following Getting Started, run:

```bash
bash scripts/ci/onboarding_check.sh
```

Checks 1–5 validate Node, install, typecheck, lint, and tests (no runtime required). Checks 6–10 probe the runtime when it is running; they **skip** gracefully when offline.

## What's Blocked

Active blockers on [Project 2](https://github.com/orgs/traverse-framework/projects/2):

- **SSE state subscription** ([#43](https://github.com/traverse-framework/reference-apps/issues/43)) — replace polling with runtime SSE; blocked on [Traverse #525](https://github.com/traverse-framework/Traverse/issues/525), [#526](https://github.com/traverse-framework/Traverse/issues/526), [#527](https://github.com/traverse-framework/Traverse/issues/527). All platform clients inherit this blocker for Phase 2 SSE upgrade.
- **meeting-notes web-react** ([#57](https://github.com/traverse-framework/reference-apps/issues/57)) — second domain app (list-type output); blocked pending runtime capability work.
- **doc-approval shared core** ([#72](https://github.com/traverse-framework/reference-apps/issues/72), [#73](https://github.com/traverse-framework/reference-apps/issues/73)) — extract shared Swift/Rust client packages for iOS/macOS and linux-gtk/cli-rust; Phase 2 work blocked on SSE and crate design.
