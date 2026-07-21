# Reference Apps

[![CI](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml)

Reference UI applications for the [Traverse](https://github.com/traverse-framework/Traverse) framework.

**Architecture in one sentence:** This repo is UI-only. Each platform ships a **native UI shell** with an **embedded Traverse WASM runtime** (Phase 3 target). Business logic lives in bundled WASM agents; the UI starts workflows and renders runtime-provided output only.

> **Current state:** All seven primary platform clients embed the WASM runtime (Web, Linux, CLI, Android, Windows, iOS, macOS) — no sidecar required for production.  
> **Start here:** [`docs/production-playbook.md`](docs/production-playbook.md) · hands-on [`docs/getting-started-embedded.md`](docs/getting-started-embedded.md).


## Prerequisites

- **Node.js 24+** (see `.nvmrc`)
- **Rust 1.94+** (to build and run the Traverse runtime)
- **`gh` CLI** (for agents claiming Project 2 tickets)

## Getting Started (embedded — production path)

Business logic lives in WASM once; each UI shell only submits input and renders runtime-owned fields. **All seven platforms** embed — no `traverse-cli serve` required for production.

Follow the guided walkthrough: **[`docs/getting-started-embedded.md`](docs/getting-started-embedded.md)**.

**Quick start (Web):**

```bash
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps
npm install
export TRAVERSE_REPO=/path/to/Traverse   # checkout with example WASM
bash scripts/ci/sync_web_starter_bundle.sh
npm run dev                              # traverse-starter embedded web shell
```

Digest-pinned bundle sync (all platforms): [`docs/runtime-bundle-sync.md`](docs/runtime-bundle-sync.md).  
Multi-OS packaging + release evidence: [`docs/production-packaging.md`](docs/production-packaging.md).

## Primary vs secondary apps

This repo has two maintenance tiers. Do **not** treat Expedition demos as the same bar as Phase 3/4 reference shells.

| Tier | Apps | Maintenance bar | `embedded_smoke` (#118) |
|---|---|---|---|
| **Primary product shells** | `traverse-starter`, `doc-approval`, `meeting-notes` | Full: embed path, digest pin, SDK doubles, production DoD | Hard-fail targets for Linux-runnable primary platforms |
| **Adopted / secondary** | `react-demo`, `android-demo`, `macos-demo`, `browser-consumer`, `youaskm3-starter-kit` | Lighter: offline/live demo smokes; not the copy-paste production kit | **Not** merge-blocking smoke targets |
| **Debugger exception** | `trace-explorer` | Named HTTP client until Traverse embeds a trace API (Project 2: `embed-trace-explorer`) | Not a product shell to copy |

Details: [`docs/adopted-platform-clients.md`](docs/adopted-platform-clients.md) · kit roadmap: [`docs/production-reference-plan.md`](docs/production-reference-plan.md).

Open `http://localhost:5173`. Submit a note when the embedded host is ready; confirm title / tags / note type / suggested next action / status come from the runtime.

Other Vite apps (one at a time on port 5173):

```bash
npm run dev -w apps/doc-approval/web-react               # embedded + pipeline
npm run dev -w apps/meeting-notes/web-react              # meeting-notes
npm run dev -w apps/trace-explorer/web-react             # trace-explorer
```

### Dev sidecar (Phase 1/2 interim)

Optional HTTP integration / historical Phase 1 path (not required for embedded platforms):

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

The sidecar listens on `http://127.0.0.1:8787` and writes `.traverse/server.json`. See [`docs/traverse-runtime.md`](docs/traverse-runtime.md).


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
| [`apps/meeting-notes/`](apps/meeting-notes/) | meeting-notes clients (web, Linux GTK, CLI) |
| [`apps/trace-explorer/web-react/`](apps/trace-explorer/web-react/) | Trace Explorer — execution timeline debugger |
| [`apps/react-demo/`](apps/react-demo/) | Expedition React browser demo (adopted from Traverse) |
| [`apps/browser-consumer/`](apps/browser-consumer/) | Browser consumer façade for downstream apps |
| [`apps/android-demo/`](apps/android-demo/) | Expedition Android demo |
| [`apps/macos-demo/`](apps/macos-demo/) | Expedition macOS demo |
| [`apps/youaskm3-starter-kit/`](apps/youaskm3-starter-kit/) | youaskm3 browser starter kit |
| [`docs/adopted-platform-clients.md`](docs/adopted-platform-clients.md) | Canonical homes for adopted Traverse demos |
| [`docs/production-playbook.md`](docs/production-playbook.md) | **Production playbook** — embedded-first multi-OS shipping guide |
| [`docs/add-platform-client.md`](docs/add-platform-client.md) | Recipe: add a new OS / UI shell from the reference pattern |
| [`docs/getting-started-embedded.md`](docs/getting-started-embedded.md) | Hands-on embedded onboarding (Web + Linux/CLI) |
| [`docs/embedded-runtime-plan.md`](docs/embedded-runtime-plan.md) | Phase 3 — embedded runtime + multi-capability workflows |
| [`docs/production-reference-plan.md`](docs/production-reference-plan.md) | Phase 4 — production kit roadmap (CI, packaging, docs, agent ops) |
| [`docs/traverse-runtime.md`](docs/traverse-runtime.md) | Dev sidecar appendix (deprecated / Trace Explorer) |
| [`manifests/traverse-starter/`](manifests/traverse-starter/) | App manifest + component manifests (Phase 2) |
| [`fixtures/`](fixtures/) | Shared UI demo fixtures (e.g. expedition session) |
| [`scripts/ci/`](scripts/ci/) | Repository checks, smoke tests, coverage gate |

## Platform clients

All **primary** clients are **native UI shells** with an **embedded** Traverse WASM host ([#113](https://github.com/traverse-framework/reference-apps/issues/113)–[#118](https://github.com/traverse-framework/reference-apps/issues/118)). Business logic stays in WASM; the UI submits input and renders runtime-owned fields. See [`docs/production-playbook.md`](docs/production-playbook.md).

### traverse-starter

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped (embedded) | [`apps/traverse-starter/web-react/`](apps/traverse-starter/web-react/) |
| trace-explorer (React) | Shipped | [`apps/trace-explorer/web-react/`](apps/trace-explorer/web-react/) |
| iOS (SwiftUI) | Shipped (embedded) | [`apps/traverse-starter/ios-swift/`](apps/traverse-starter/ios-swift/) |
| macOS (SwiftUI + AppKit) | Shipped (embedded) | [`apps/traverse-starter/macos-swift/`](apps/traverse-starter/macos-swift/) |
| Android (Jetpack Compose) | Shipped (embedded) | [`apps/traverse-starter/android-compose/`](apps/traverse-starter/android-compose/) |
| Windows (WinUI 3) | Shipped (embedded) | [`apps/traverse-starter/windows-winui/`](apps/traverse-starter/windows-winui/) |
| Linux (GTK4 + Rust) | Shipped (embedded) | [`apps/traverse-starter/linux-gtk/`](apps/traverse-starter/linux-gtk/) |
| CLI (Rust) | Shipped (embedded) | [`apps/traverse-starter/cli-rust/`](apps/traverse-starter/cli-rust/) |

### doc-approval (Phase 1 submitter)

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped (embedded + pipeline) | [`apps/doc-approval/web-react/`](apps/doc-approval/web-react/) |
| iOS (SwiftUI) | Shipped (embedded + pipeline) | [`apps/doc-approval/ios-swift/`](apps/doc-approval/ios-swift/) |
| macOS (SwiftUI + AppKit) | Shipped (embedded + pipeline) | [`apps/doc-approval/macos-swift/`](apps/doc-approval/macos-swift/) |
| Android (Jetpack Compose) | Shipped (embedded + pipeline) | [`apps/doc-approval/android-compose/`](apps/doc-approval/android-compose/) |
| Windows (WinUI 3) | Shipped (embedded + pipeline) | [`apps/doc-approval/windows-winui/`](apps/doc-approval/windows-winui/) |
| Linux (GTK4 + Rust) | Shipped (embedded + pipeline) | [`apps/doc-approval/linux-gtk/`](apps/doc-approval/linux-gtk/) |
| CLI (Rust) | Shipped (embedded + pipeline) | [`apps/doc-approval/cli-rust/`](apps/doc-approval/cli-rust/) |

### meeting-notes (list-type output)

| Platform | Status | Path |
|---|---|---|
| Web (React + TypeScript) | Shipped (embedded) | [`apps/meeting-notes/web-react/`](apps/meeting-notes/web-react/) |
| Linux (GTK4 + Rust) | Shipped (embedded) | [`apps/meeting-notes/linux-gtk/`](apps/meeting-notes/linux-gtk/) |
| CLI (Rust) | Shipped (embedded) | [`apps/meeting-notes/cli-rust/`](apps/meeting-notes/cli-rust/) |

## Development

```bash
npm run dev            # traverse-starter dev server
npm run typecheck
npm run lint
npm run test
bash scripts/ci/repository_checks.sh
bash scripts/ci/embedded_smoke.sh     # embedded E2E: init → pipeline → runtime-owned fields (set TRAVERSE_REPO)
bash scripts/ci/phase1_smoke.sh       # sidecar path (requires running runtime)
bash scripts/ci/onboarding_check.sh   # local setup verification (runtime steps skip if offline)
```

### Native clients

Native platforms (iOS, macOS, Android, Windows, Linux, CLI) are built and run from their app directories. Each **primary** platform README documents **Runtime mode: Embedded**, bundle sync, and test commands — not a sidecar URL.

| Platform | Typical entry point |
|---|---|
| iOS / macOS | Open the `.xcodeproj` in Xcode → Run (⌘R) |
| Android | `cd apps/<app>/android-compose && ./gradlew test` |
| Windows | Open the `.sln` in Visual Studio |
| Linux GTK / CLI | `cargo test` / `cargo run` in `apps/<app>/linux-gtk` or `cli-rust` |

**Sidecar URL (deprecated carve-outs only):** Trace Explorer (`embed-trace-explorer`) and legacy Phase 1 scripts. See the [exception list](docs/traverse-runtime.md#named-http-carve-outs-exception-list).

See [`docs/production-playbook.md`](docs/production-playbook.md) for the shipping guide.

## Verify Your Setup

After following Getting Started, run:

```bash
bash scripts/ci/onboarding_check.sh
```

Checks 1–5 validate Node, install, typecheck, lint, and tests (no runtime required). Checks 6–10 probe the runtime when it is running; they **skip** gracefully when offline.

## What's Blocked

No active Project 2 **Blocked** items that are App-Refs-only engineering. Upstream-gated tickets (`embed-trace-explorer`, `registry-ref-starter-process`, `consume-product-wasm-agents`) and Future showcase/cleanup tickets live on [Project 2](https://github.com/orgs/traverse-framework/projects/2) — see [`docs/production-reference-plan.md`](docs/production-reference-plan.md) and `AGENTS.md`.

