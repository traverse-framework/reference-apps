# Reference Apps

[![CI](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml)

Reference UI applications for the [Traverse](https://github.com/traverse-framework/Traverse) framework.

**Architecture in one sentence:** This repo is UI-only. Each platform ships a **native UI shell** with an **embedded Traverse WASM runtime** (Phase 3 target). Business logic lives in bundled WASM agents; the UI starts workflows and renders runtime-provided output only.

> **Current state:** Phase 1/2 clients still use an HTTP dev sidecar (`traverse-cli serve`). Phase 3 migration is tracked on [Project 2](https://github.com/orgs/traverse-framework/projects/2). See [`docs/embedded-runtime-plan.md`](docs/embedded-runtime-plan.md).

## Prerequisites

- **Node.js 24+** (see `.nvmrc`)
- **Rust 1.94+** (to build and run the Traverse runtime)
- **`gh` CLI** (for agents claiming Project 2 tickets)

## Getting Started (Phase 1/2 dev sidecar)

Until Phase 3 embedded runtime lands, local development uses a separate Traverse process.

**1. Clone and install**

```bash
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps
npm install
```

**2. Start the Traverse dev sidecar** (separate terminal — not required in Phase 3)

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

The runtime listens on `http://127.0.0.1:8787` by default and writes `.traverse/server.json` with `base_url` and `workspace_default`. See [`docs/traverse-runtime.md`](docs/traverse-runtime.md) for pinned versions and API details.

**3. Start a web client** (from the repo root; only one Vite app at a time on port 5173)

```bash
npm run dev                                              # traverse-starter (default)
npm run dev -w apps/doc-approval/web-react               # doc-approval
npm run dev -w apps/meeting-notes/web-react              # meeting-notes
npm run dev -w apps/trace-explorer/web-react             # trace-explorer
```

Open `http://localhost:5173`. Submit input when the runtime health strip shows **Online**.

## What You Will See

### traverse-starter

Three panels:

1. **Runtime Environment** — runtime URL, online/offline status, workspace, capability ID
2. **Start Workflow** — note input and submit (disabled when runtime is offline)
3. **Execution Output** — runtime-provided fields: title, tags, note type, suggested next action, status, and trace events

A successful run shows all five output fields populated by the runtime. The UI computes none of them.

### doc-approval

Submitter surface: paste document text → runtime returns `docType`, `parties`, `amounts`, `confidence`, and `recommendation`.

### meeting-notes

Paste a meeting transcript → runtime returns `action_items`, `decisions`, `follow_ups`, and `summary`. Demonstrates **list-type structured output** (object arrays) vs traverse-starter's flat string fields.

### trace-explorer

Developer tool for browsing execution traces — not a domain workflow app.

## Reference apps

| App | Purpose | Web path | Default capability |
|---|---|---|---|
| traverse-starter | Flat string output from a short note | [`apps/traverse-starter/web-react/`](apps/traverse-starter/web-react/) | `traverse-starter.process` |
| doc-approval | Document analysis submitter | [`apps/doc-approval/web-react/`](apps/doc-approval/web-react/) | `doc-approval.pipeline` |
| meeting-notes | List-type output from a transcript | [`apps/meeting-notes/web-react/`](apps/meeting-notes/web-react/) | `meeting-notes.process` |
| trace-explorer | Execution timeline debugger | [`apps/trace-explorer/web-react/`](apps/trace-explorer/web-react/) | — |

Each app also ships native clients (iOS, macOS, Android, Windows, Linux, CLI) where listed in [Platform clients](#platform-clients) below. Per-app READMEs under `apps/<app>/<platform>/README.md` cover build, run, and runtime URL settings.

## Project Structure

| Path | Purpose |
|---|---|
| [`apps/traverse-starter/`](apps/traverse-starter/) | traverse-starter clients (all platforms) |
| [`apps/doc-approval/`](apps/doc-approval/) | doc-approval clients (all platforms) |
| [`apps/meeting-notes/`](apps/meeting-notes/) | meeting-notes clients (web-react shipped) |
| [`apps/trace-explorer/web-react/`](apps/trace-explorer/web-react/) | Trace Explorer — execution timeline debugger |
| [`apps/react-demo/`](apps/react-demo/) | Expedition React browser demo (adopted from Traverse) |
| [`apps/browser-consumer/`](apps/browser-consumer/) | Browser consumer façade for downstream apps |
| [`apps/android-demo/`](apps/android-demo/) | Expedition Android demo |
| [`apps/macos-demo/`](apps/macos-demo/) | Expedition macOS demo |
| [`apps/youaskm3-starter-kit/`](apps/youaskm3-starter-kit/) | youaskm3 browser starter kit |
| [`docs/adopted-platform-clients.md`](docs/adopted-platform-clients.md) | Canonical homes for adopted Traverse demos |
| [`docs/embedded-runtime-plan.md`](docs/embedded-runtime-plan.md) | Phase 3 target — embedded runtime + multi-capability workflows |
| [`docs/traverse-runtime.md`](docs/traverse-runtime.md) | Dev sidecar setup (Phase 1/2) |
| [`manifests/traverse-starter/`](manifests/traverse-starter/) | App manifest + component manifests (Phase 2) |
| [`fixtures/`](fixtures/) | Shared UI demo fixtures (e.g. expedition session) |
| [`scripts/ci/`](scripts/ci/) | Repository checks, smoke tests, coverage gate |

## Platform clients

All clients are **native UI shells** separated from business logic. Phase 1/2 use an HTTP dev sidecar; **Phase 3 embeds the WASM runtime in every app** ([#109](https://github.com/traverse-framework/reference-apps/issues/109)–[#118](https://github.com/traverse-framework/reference-apps/issues/118)). Web SSE + `sendCommand` shipped in [#43](https://github.com/traverse-framework/reference-apps/issues/43); native platforms can follow that pattern.

### traverse-starter

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped (embedded) | [`apps/traverse-starter/web-react/`](apps/traverse-starter/web-react/) |
| trace-explorer (React) | Shipped | [`apps/trace-explorer/web-react/`](apps/trace-explorer/web-react/) |
| iOS (SwiftUI) | Shipped | [`apps/traverse-starter/ios-swift/`](apps/traverse-starter/ios-swift/) |
| macOS (SwiftUI + AppKit) | Shipped | [`apps/traverse-starter/macos-swift/`](apps/traverse-starter/macos-swift/) |
| Android (Jetpack Compose) | Shipped | [`apps/traverse-starter/android-compose/`](apps/traverse-starter/android-compose/) |
| Windows (WinUI 3) | Shipped | [`apps/traverse-starter/windows-winui/`](apps/traverse-starter/windows-winui/) |
| Linux (GTK4 + Rust) | Shipped (embedded) | [`apps/traverse-starter/linux-gtk/`](apps/traverse-starter/linux-gtk/) |
| CLI (Rust) | Shipped (embedded) | [`apps/traverse-starter/cli-rust/`](apps/traverse-starter/cli-rust/) |

### doc-approval (Phase 1 submitter)

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped (embedded + pipeline) | [`apps/doc-approval/web-react/`](apps/doc-approval/web-react/) |
| iOS (SwiftUI) | Shipped (pipeline via HTTP) | [`apps/doc-approval/ios-swift/`](apps/doc-approval/ios-swift/) |
| macOS (SwiftUI + AppKit) | Shipped (pipeline via HTTP) | [`apps/doc-approval/macos-swift/`](apps/doc-approval/macos-swift/) |
| Android (Jetpack Compose) | Shipped (pipeline via HTTP) | [`apps/doc-approval/android-compose/`](apps/doc-approval/android-compose/) |
| Windows (WinUI 3) | Shipped (pipeline via HTTP) | [`apps/doc-approval/windows-winui/`](apps/doc-approval/windows-winui/) |
| Linux (GTK4 + Rust) | Shipped (embedded + pipeline) | [`apps/doc-approval/linux-gtk/`](apps/doc-approval/linux-gtk/) |
| CLI (Rust) | Shipped (embedded + pipeline) | [`apps/doc-approval/cli-rust/`](apps/doc-approval/cli-rust/) |

### meeting-notes (list-type output)

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped | [`apps/meeting-notes/web-react/`](apps/meeting-notes/web-react/) |

## Development

```bash
npm run dev            # traverse-starter dev server
npm run typecheck
npm run lint
npm run test
bash scripts/ci/repository_checks.sh
bash scripts/ci/phase1_smoke.sh       # requires running runtime
bash scripts/ci/onboarding_check.sh   # local setup verification (runtime steps skip if offline)
```

### Native clients

Native platforms (iOS, macOS, Android, Windows, Linux, CLI) are built and run from their app directories. Each platform README documents prerequisites, runtime URL configuration, and test commands.

| Platform | Typical entry point |
|---|---|
| iOS / macOS | Open the `.xcodeproj` in Xcode → Run (⌘R) |
| Android | `cd apps/<app>/android-compose && ./gradlew test` |
| Windows | Open the `.sln` in Visual Studio |
| Linux GTK / CLI | `cargo test` in `apps/<app>/linux-gtk` or `cli-rust` |

**Runtime URL:** loopback clients use `http://127.0.0.1:8787`. Android emulator uses `http://10.0.2.2:8787` for host loopback.

See [docs/traverse-starter-plan.md](docs/traverse-starter-plan.md) for the full plan and [docs/traverse-runtime.md](docs/traverse-runtime.md) for runtime setup.

## Verify Your Setup

After following Getting Started, run:

```bash
bash scripts/ci/onboarding_check.sh
```

Checks 1–5 validate Node, install, typecheck, lint, and tests (no runtime required). Checks 6–10 probe the runtime when it is running; they **skip** gracefully when offline.

## What's Blocked

Active blockers on [Project 2](https://github.com/orgs/traverse-framework/projects/2):

- **Phase 3 embedded runtime** ([#114](https://github.com/traverse-framework/reference-apps/issues/114)–[#116](https://github.com/traverse-framework/reference-apps/issues/116)) — Blocked until Traverse ships executable WASM embedder bridges: [#647](https://github.com/traverse-framework/Traverse/issues/647) (Swift), [#648](https://github.com/traverse-framework/Traverse/issues/648) (Kotlin), [#649](https://github.com/traverse-framework/Traverse/issues/649) (.NET). Package scaffolds exist; `InMemoryTraverseEmbedder` alone cannot meet no-sidecar DoD. Rust/Web embeds shipped ([#117](https://github.com/traverse-framework/reference-apps/issues/117), [#113](https://github.com/traverse-framework/reference-apps/issues/113)).

Ready on Project 2: none (query the live board).
