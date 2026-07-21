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
- Embedded runtime smoke (`bash scripts/ci/embedded_smoke.sh`) — merge-blocking for the Linux-runnable subset (`web` + `rust-cli`); other platform slices skip with reason until #88
## Coverage Standard

Required coverage for non-trivial UI logic:

- Event parsing and transformation
- UI state machine (loading, progress, error, final)
- Any hook that computes derived state from runtime events

Coverage gate implementation:

- script: `scripts/ci/coverage_gate.sh`
- threshold: defined in `scripts/ci/coverage_gate.sh`

The coverage gate is merge-safe before non-trivial logic exists — it passes when no covered targets are configured.

## Native Platform Clients

Native clients follow the UI-only boundary: **native UI separated from business logic**. Business fields come from the embedded Traverse host (Phase 3) or dev HTTP sidecar (Phase 1/2 interim).

**Runtime boundary (interim):** public HTTP/JSON API ([spec 033](https://github.com/traverse-framework/Traverse/blob/main/docs/specs/033-http-json-api.md)) for dev sidecar only.

**Runtime boundary (target):** public embedded host SDK from Traverse — in-process execute, event subscription, bundled manifests + WASM. No `127.0.0.1:8787` in production builds.

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

Each platform README documents runtime setup (`cargo run -p traverse-cli -- serve`) and any platform-specific prerequisites.

**Test expectations**:

- Non-trivial client logic (HTTP client wrappers, execution state machines, output parsing) must have unit tests where the platform toolchain supports them
- Tests must not fake runtime business decisions — use HTTP mocks or documented stubs scoped to tests
- Scaffolds with no non-trivial logic yet may ship with build-only validation until logic lands; add tests in the same PR when non-trivial logic is introduced

Native CI build gates are tracked separately (issue #88); until those land, local build + test commands above are the merge validation bar for native client changes.

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
- The change lacks a GitHub issue + Project 2 item + PR

## Nightly CI Gate

A nightly job runs the Phase 1 smoke test independently of any PR activity.

**Schedule**: daily at 06:00 UTC (`.github/workflows/nightly.yml`)

**What it validates**:
- Phase 1 end-to-end smoke (`scripts/ci/phase1_smoke.sh`)
- Repository structure checks (`scripts/ci/repository_checks.sh`)
- TypeScript, lint, and test suite

**SLA**: any nightly failure must be investigated within 24 hours. A broken nightly sitting more than 24 hours is a P1 issue.

**Manual trigger**: the workflow supports `workflow_dispatch`.

## Problem Handling Rule

When active work reveals a problem:

- must-fix issues (correctness, mergeability, governance) must be resolved in the current PR
- non-blocking follow-ups must be captured as `future` tickets instead of being left implicit
