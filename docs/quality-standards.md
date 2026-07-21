# Quality Standards

This document defines the operational quality standards for App-References.

These standards work together with the constitution. If there is a conflict, the constitution takes precedence.

## Core Rule

Code is not considered mergeable unless it is:

- aligned with the UI-only architecture boundary
- validated by the required automated checks
- maintainable at production quality
- free of leaked business logic or private Traverse internals

## Engineering Standards

All in-scope code must meet these standards:

- Clear component and hook boundaries
- No business decisions in the rendering layer
- Deterministic rendering for the same runtime-provided inputs
- Actionable error and loading states driven by runtime events
- Testability by design for non-trivial UI logic
- No hidden coupling to Traverse internals
- No fake runtime behavior in application code

## Required Validation Gates

The default validation flow includes:

- TypeScript type check (`npm run typecheck`)
- ESLint (`npm run lint`)
- Unit tests (`npm run test`)
- Coverage gate for non-trivial UI logic (`npm run test:coverage`)
- Repository structure check (`bash scripts/ci/repository_checks.sh`)
- PR body validation (`bash scripts/ci/pr_body_check.sh`)

## Coverage Standard

Required coverage for non-trivial UI logic:

- Event parsing and transformation
- UI state machine (loading, progress, error, final)
- Any hook that computes derived state from runtime events

Coverage gate implementation:

- script: `scripts/ci/coverage_gate.sh`
- threshold: **100%** lines for configured targets (`scripts/ci/coverage_gate.sh`, default)

The coverage gate is merge-safe before non-trivial logic exists — it passes when no covered targets are configured.

## Native Platform Clients

Native clients follow the UI-only boundary: **native UI separated from business logic**. Business fields come from the **embedded** Traverse host on primary platforms.

**Runtime boundary (production):** public embedded host SDK — in-process execute, event subscription, bundled manifests + WASM. No `127.0.0.1:8787` in production builds. See [`production-playbook.md`](production-playbook.md).

**Runtime boundary (deprecated sidecar):** public HTTP/JSON API ([spec 033](https://github.com/traverse-framework/Traverse/blob/main/docs/specs/033-http-json-api.md)) for Trace Explorer / legacy smoke only ([`traverse-runtime.md`](traverse-runtime.md)).

See [`docs/embedded-runtime-plan.md`](embedded-runtime-plan.md) for the Phase 3 platform matrix.

**IA parity**: native shells must match the traverse-starter information architecture documented in [`docs/design-language.md`](design-language.md).

**Platform paths** (see also the Platform clients table in [`AGENTS.md`](../AGENTS.md)):

| Platform | Path | Local build + test |
|---|---|---|
| iOS (SwiftUI) | `apps/traverse-starter/ios-swift/` | `xcodebuild -scheme TraverseStarter -destination 'platform=iOS Simulator,name=iPhone 16' build test` |
| macOS (SwiftUI) | `apps/traverse-starter/macos-swift/` | `xcodebuild -scheme TraverseStarterMac -destination 'platform=macOS' build test` |
| Android (Compose) | `apps/traverse-starter/android-compose/` | `./gradlew :app:assembleDebug :app:testDebugUnitTest` |
| Windows (WinUI 3) | `apps/traverse-starter/windows-winui/` | `dotnet build TraverseStarter.sln -c Release` and `dotnet test TraverseStarter.sln -c Release` |
| Linux (GTK4 + Rust) | `apps/traverse-starter/linux-gtk/` | `cargo build`, `cargo test` |
| CLI (Rust) | `apps/traverse-starter/cli-rust/` | `cargo build --release`, `cargo test` |

Each primary platform README documents **Runtime mode: Embedded** and sync/test commands (not sidecar URL setup).

**Test expectations**:

- Non-trivial client logic (HTTP client wrappers, execution state machines, output parsing) must have unit tests where the platform toolchain supports them
- Tests must not fake runtime business decisions — use HTTP mocks or documented stubs scoped to tests
- Scaffolds with no non-trivial logic yet may ship with build-only validation until logic lands; add tests in the same PR when non-trivial logic is introduced

Native CI build gates (#88, tiered):

| Gate | When | Job |
|---|---|---|
| Linux `cargo test` (traverse-starter + doc-approval: **core + CLI**) | **PR merge-blocking** | `native-linux` in `.github/workflows/ci.yml` |
| Linux GTK `cargo test` | **Nightly required** | `native-linux-gtk` in `.github/workflows/nightly.yml` |
| macOS `xcodebuild` (TraverseStarterMac + DocApprovalMac) | **Nightly required** | `native-macos` in `.github/workflows/nightly.yml` |
| Windows `dotnet test` (WinUI solutions) | **Nightly required** | `native-windows` in `.github/workflows/nightly.yml` |
| Android `./gradlew testDebugUnitTest` | **Nightly required** | `native-android` in `.github/workflows/nightly.yml` |

Local commands above remain the developer validation bar when editing a single platform.

## Reproducibility Standard

Build and validation flows must be reproducible from pinned inputs:

- pinned Node.js version (`.nvmrc` or `engines` in `package.json`)
- pinned dependencies (`package-lock.json` or equivalent)
- documented commands (this doc and `CLAUDE.md`)
- CI using the same commands expected locally

## Merge Blocking Conditions

A change must not merge when any of the following are true:

- TypeScript type errors exist
- ESLint violations exist
- Unit tests fail
- Required coverage threshold is not met
- Repository structure check fails
- PR body is missing required sections
- Business logic is implemented in the UI layer
- Private Traverse internals are imported
- Fake runtime behavior exists in application code
- The change lacks a Project 2 ticket (Spec + DoD) + PR

## Embedded smoke (PR merge-blocking)

Every PR runs `scripts/ci/embedded_smoke.sh` with `EMBEDDED_SMOKE_EXPECT=linux` (`.github/workflows/ci.yml` job `embedded-smoke`):

- Requires Web (`BundleEmbedder` init + full pipeline → validate/process/summarize fields) and Rust CLI (`health` + `run` with the same output shape)
- Uses smoke WASI fixtures when Traverse example agents are stubs; still public embedder path only
- Skips Apple / Windows / Android SDK slices with reason when tools are absent; still digest-checks committed `runtime.wasm`
- Does **not** start `traverse-cli serve`
- Coverage gate for `host/embeddedHost.ts` + `client/traverseOutput.ts` is **100%** line coverage

## Native Linux cargo (PR merge-blocking)

Every PR runs Linux native cargo tests (job `native-linux`): `traverse-core-rs` / `traverse-starter-cli` and the doc-approval equivalents. GTK shells run on nightly as **required** (`native-linux-gtk`).

## Nightly CI Gate

Nightly (`.github/workflows/nightly.yml`, 06:00 UTC + `workflow_dispatch`):

- Phase 1 sidecar smoke (`phase1_smoke.sh`) + Node quality suite (`golden-path`)
- **Required:** `native-macos`, `native-windows`, `native-linux-gtk`, `native-android`

**SLA**: any required nightly failure must be investigated within 24 hours. A broken required nightly sitting more than 24 hours is a P1 issue.

## Problem Handling Rule

When active work reveals a problem:

- must-fix issues (correctness, mergeability, governance) must be resolved in the current PR
- non-blocking follow-ups must be captured as `future` tickets instead of being left implicit
