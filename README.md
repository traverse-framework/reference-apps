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

Until Phase 3 embedded runtime lands, local development uses a separate Traverse process:
```bash
# 1. Clone this repo
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps

# 2. Clone and start the Traverse dev sidecar (separate terminal — not required in Phase 3)

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
| [`docs/embedded-runtime-plan.md`](docs/embedded-runtime-plan.md) | Phase 3 target — embedded runtime + multi-capability workflows |
| [`docs/traverse-runtime.md`](docs/traverse-runtime.md) | Dev sidecar setup (Phase 1/2) |
| [`manifests/traverse-starter/`](manifests/traverse-starter/) | App manifest + component manifests (Phase 2) |
| [`scripts/ci/`](scripts/ci/) | Repository checks, smoke tests, coverage gate |

## Platform clients

All clients are **native UI shells** separated from business logic. Phase 1/2 use an HTTP dev sidecar; **Phase 3 embeds the WASM runtime in every app** ([#109](https://github.com/traverse-framework/reference-apps/issues/109)–[#118](https://github.com/traverse-framework/reference-apps/issues/118)). SSE upgrade tracked in [#43](https://github.com/traverse-framework/reference-apps/issues/43).

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
bash scripts/ci/phase1_smoke.sh   # requires running runtime
bash scripts/ci/onboarding_check.sh   # local setup verification (runtime steps skip if offline)
```

### doc-approval native testing on macOS

Platforms testable on a Mac without a Linux/Windows VM: **web-react**, **cli-rust**, **macos-swift**, **ios-swift**, **android-compose**.

**One-time prerequisites**

| Tool | Purpose | Install |
|---|---|---|
| Xcode 16+ | iOS + macOS | App Store |
| JDK 17 | Android Gradle tests | `brew install openjdk@17` |
| Android command-line tools | SDK for Gradle + emulator | `brew install android-commandlinetools` |
| Android Studio | Android emulator (manual runs) | [developer.android.com](https://developer.android.com/studio) (optional if using CLI SDK) |
| Rust | CLI client | [rustup.rs](https://rustup.rs/) |

**Check prerequisites**

```bash
source scripts/dev/android-env.sh   # JAVA_HOME + ANDROID_HOME (after brew install below)
bash scripts/dev/check-native-prerequisites.sh
```

**Android SDK one-time install (Homebrew, no Android Studio required for unit tests)**

```bash
brew install openjdk@17 android-commandlinetools
source scripts/dev/android-env.sh
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
```

**Run all macOS-testable unit tests**

```bash
bash scripts/dev/test-doc-approval-macos.sh
# optional E2E when runtime is up:
bash scripts/dev/test-doc-approval-macos.sh --with-runtime-smoke
```

Per-app READMEs under `apps/doc-approval/*/README.md` cover manual GUI runs and runtime URL settings (Android emulator uses `http://10.0.2.2:8787` for host loopback).

### Run the apps visually (manual testing)

**1. Start the runtime** (keep this terminal open):

```bash
cd /tmp/traverse && cargo run -p traverse-cli -- serve
```

**2. Launch a client** (pick one per terminal/window):

```bash
bash scripts/dev/launch-doc-approval.sh web       # browser → http://localhost:5173
bash scripts/dev/launch-doc-approval.sh macos     # opens Xcode → press ⌘R
bash scripts/dev/launch-doc-approval.sh ios       # opens Xcode + Simulator → press ⌘R
bash scripts/dev/launch-doc-approval.sh android   # starts emulator, installs app
bash scripts/dev/launch-doc-approval.sh           # show menu
```

| App | How you see it | Runtime URL in settings |
|-----|----------------|-------------------------|
| Web | Browser at `http://localhost:5173` | `http://127.0.0.1:8787` (in `.env`) |
| macOS | DocApprovalMac window | `http://127.0.0.1:8787` (⌘,) |
| iOS | iPhone Simulator | `http://127.0.0.1:8787` (Settings) |
| Android | Emulator | `http://10.0.2.2:8787` (Settings) |

Paste document text → **Analyze** / submit → you should see analysis fields when the runtime is online and the capability is registered.

See [docs/traverse-starter-plan.md](docs/traverse-starter-plan.md) for the full plan and [docs/traverse-runtime.md](docs/traverse-runtime.md) for runtime setup.

## Verify Your Setup

After following Getting Started, run:

```bash
bash scripts/ci/onboarding_check.sh
```

Checks 1–5 validate Node, install, typecheck, lint, and tests (no runtime required). Checks 6–10 probe the runtime when it is running; they **skip** gracefully when offline.

## What's Blocked

Active blockers on [Project 2](https://github.com/orgs/traverse-framework/projects/2):

- **Phase 3 embedded runtime** ([#109](https://github.com/traverse-framework/reference-apps/issues/109)–[#118](https://github.com/traverse-framework/reference-apps/issues/118)) — all platform clients must bundle the WASM runtime host; blocked on a **consumable platform embedder SDK** (Traverse [#553](https://github.com/traverse-framework/Traverse/issues/553) closed via [#578](https://github.com/traverse-framework/Traverse/pull/578) with manifest `execution_mode` only). HTTP sidecar is dev-only.
- **Multi-capability showcase workflow** ([#110](https://github.com/traverse-framework/reference-apps/issues/110), [#111](https://github.com/traverse-framework/reference-apps/issues/111)) — traverse-starter and doc-approval pipeline workflows with multiple WASM capabilities.
- **SSE state subscription** ([#43](https://github.com/traverse-framework/reference-apps/issues/43)) — replace polling with runtime SSE; blocked on [Traverse #527](https://github.com/traverse-framework/Traverse/issues/527) only (#525/#526 done).
- **Embedded runtime client packages** ([#58](https://github.com/traverse-framework/reference-apps/issues/58), [#59](https://github.com/traverse-framework/reference-apps/issues/59), [#72](https://github.com/traverse-framework/reference-apps/issues/72), [#73](https://github.com/traverse-framework/reference-apps/issues/73)) — shared Swift/Rust host wiring for embedded mode; reprioritized from HTTP client extraction.
