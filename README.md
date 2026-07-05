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
| [`docs/`](docs/) | Plan, runtime setup, quality standards |
| [`manifests/traverse-starter/`](manifests/traverse-starter/) | App manifest + component manifests (Phase 2) |
| [`scripts/ci/`](scripts/ci/) | Repository checks, smoke tests, coverage gate |

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

Platform expansion and SSE-based state subscription are blocked on Traverse runtime work:

- **SSE state subscription** ([#43](https://github.com/traverse-framework/reference-apps/issues/43)) — blocked on [Traverse #525](https://github.com/traverse-framework/Traverse/issues/525), [#526](https://github.com/traverse-framework/Traverse/issues/526), [#527](https://github.com/traverse-framework/Traverse/issues/527)
- **iOS Swift client** ([#44](https://github.com/traverse-framework/reference-apps/issues/44)) — blocked on [Traverse #522](https://github.com/traverse-framework/Traverse/issues/522), [#525](https://github.com/traverse-framework/Traverse/issues/525)
- **macOS Swift client** ([#45](https://github.com/traverse-framework/reference-apps/issues/45)) — same blockers as iOS

Track active work on [Project 2](https://github.com/orgs/traverse-framework/projects/2).
