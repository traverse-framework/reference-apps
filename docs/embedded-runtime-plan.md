# Phase 3 — Embedded Runtime Plan

## Purpose

App-References must demonstrate the **production-shaped** Traverse integration model:

1. **Native UI per platform** — each client uses its platform toolkit (SwiftUI, Compose, WinUI, GTK, React). UI renders only; it never computes business fields.
2. **Embedded WASM runtime in every app** — the Traverse host runs **inside** the application process/bundle. No separate `traverse-cli serve` step is required for end users.
3. **Multi-capability showcase workflow** — at least one reference app runs a **single workflow** that chains **multiple WASM capabilities** so developers can see orchestration, not just one-shot execute.

Phase 1 (HTTP sidecar) and Phase 2 (CLI registration into a sidecar) remain valid **developer/integration** paths until Phase 3 lands. They are **not** the target production architecture.

## Architecture Boundary (unchanged)

| Concern | Lives in |
|---|---|
| Native UI shell | This repo — `apps/<app>/<platform>/` |
| Runtime host boundary (FFI / SDK) | Traverse repo — embeddable host per platform |
| WASM agents + workflow definitions | Traverse repo — `examples/` |
| App + component manifests | This repo — `manifests/<app>/` |
| Business output fields | Traverse runtime — UI renders, never computes |

**Constitution still applies:** no business logic in UI, no private Traverse internals imported into UI code, no fake runtime responses in application code.

## Target Deployment Model

```
┌─────────────────────────────────────────────────────────┐
│  Platform app (shipped binary / web bundle)             │
│  ┌──────────────────┐    ┌──────────────────────────┐  │
│  │ Native UI        │───►│ Embedded Traverse host   │  │
│  │ (Swift/Compose/  │    │ + bundled app manifest   │  │
│  │  WinUI/GTK/React)│◄───│ + WASM agents + workflow │  │
│  └──────────────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
         No external HTTP server required at runtime
```

### Dev vs production

| Mode | When | Runtime location | Discovery |
|---|---|---|---|
| **Production (Phase 3 target)** | Shipped apps | Embedded in app bundle | In-process SDK / local workspace path |
| **Dev sidecar (Phase 1/2)** | Local development, CI smoke | `traverse-cli serve` @ 8787 | `.traverse/server.json` or env vars |

HTTP to `127.0.0.1:8787` is a **dev convenience**, not the long-term client architecture.

## Multi-Capability Showcase

**Primary showcase app:** `traverse-starter`

One workflow (`traverse-starter.pipeline`) chains three capabilities:

| Step | Capability ID | WASM component | Input (from prior step) | Output (runtime-owned) |
|---|---|---|---|---|
| 1 | `traverse-starter.validate` | validate-agent | `{ note }` | `{ valid, issues[] }` |
| 2 | `traverse-starter.process` | process-agent (existing) | `{ note }` | `{ title, tags, noteType, suggestedNextAction, status }` |
| 3 | `traverse-starter.summarize` | summarize-agent | process output | `{ summary, wordCount }` |

The UI submits once; the workflow orchestrates steps. The UI renders **final workflow output** and trace events — it does not call capabilities individually unless explicitly designing a stepped UX (future).

**Secondary showcase app:** `doc-approval`

Workflow `doc-approval.pipeline` chains:

| Step | Capability ID | Notes |
|---|---|---|
| 1 | `doc-approval.analyze` | Existing analyze agent |
| 2 | `doc-approval.recommend` | Spec 069 final recommendation (no extract) |

Both apps must run the same workflow on all seven platform clients once embedded runtime is available.

## Platform Matrix (Phase 3 exit criteria)

Every cell must: embed runtime, bundle manifests + WASM at build time, execute multi-capability workflow end-to-end, render output without local business logic.

| Platform | traverse-starter | doc-approval |
|---|---|---|
| web-react | Required | Required |
| ios-swift | Required | Required |
| macos-swift | Required | Required |
| android-compose | Required | Required |
| windows-winui | Required | Required |
| linux-gtk | Required | Required |
| cli-rust | Required | Required |

`trace-explorer` may remain HTTP-attached for debugging until an embedded trace API exists; it is not in the Phase 3 matrix.

## Shared Client Layers

Platform-specific **UI** stays separate. Repeated **runtime host wiring** should consolidate:

| Package | Platforms | Issue |
|---|---|---|
| `TraverseCore` (Swift) | iOS + macOS | [#58](https://github.com/traverse-framework/reference-apps/issues/58), [#72](https://github.com/traverse-framework/reference-apps/issues/72) |
| `traverse-core-rs` (Rust) | linux-gtk + cli-rust | [#59](https://github.com/traverse-framework/reference-apps/issues/59), [#73](https://github.com/traverse-framework/reference-apps/issues/73) |

Phase 3 shared packages wrap the **public embedded runtime SDK** — not raw HTTP clients. HTTP client code from Phase 1 is retired from production paths after migration.

## Traverse Framework Dependencies (blocking)

Phase 3 is blocked until Traverse ships:

1. **Spec 057 embeddable runtime host** ([Traverse spec 057](https://github.com/traverse-framework/Traverse/blob/main/specs/057-embeddable-runtime-host/spec.md), issue [#557](https://github.com/traverse-framework/Traverse/issues/557)) — WASM runtime in every app; WASI wasm caps (~90%); compatible-mode native caps; uniform thin embedder API
2. **Embeddable runtime host SDK** ([Traverse #553](https://github.com/traverse-framework/Traverse/issues/553)) — implementation of spec 057
3. **Spec 058 pipeline execution** ([Traverse spec 058](https://github.com/traverse-framework/Traverse/blob/main/specs/058-workflow-pipeline-execution/spec.md)) — multi-capability workflows
4. **Additional WASM agents** — [#554](https://github.com/traverse-framework/Traverse/issues/554), [#538](https://github.com/traverse-framework/Traverse/issues/538), [#555](https://github.com/traverse-framework/Traverse/issues/555), [#556](https://github.com/traverse-framework/Traverse/issues/556)
5. **Registry spec 008** — reference capability publication ([registry spec 008](https://github.com/traverse-framework/registry/blob/main/specs/008-reference-capability-publication/spec.md))

Until (1–2) exist, platform migration tickets stay **Blocked**.

## Phase History

| Phase | Status | Model |
|---|---|---|
| Phase 1 | ✅ Shipped | HTTP sidecar, single capability execute + poll |
| Phase 2 | ✅ Shipped | CLI validate/register into sidecar workspace |
| **Phase 3** | 🎯 Target | Embedded runtime + multi-capability workflow on all platforms |

## Ticket Index (Phase 3)

| # | Title | Status |
|---|---|---|
| [109](https://github.com/traverse-framework/reference-apps/issues/109) | Land embedded runtime architecture spec | Ready |
| [Traverse #557](https://github.com/traverse-framework/Traverse/issues/557) | Spec **057** approved — embeddable runtime host | Done (spec merged) |
| [Traverse #553](https://github.com/traverse-framework/Traverse/issues/553) | Implement spec 057 SDK | Blocked → Ready after 057 PR |
| [Traverse #558](https://github.com/traverse-framework/Traverse/issues/558) | Implement spec 058 pipeline | Ready |
| [Traverse #527](https://github.com/traverse-framework/Traverse/issues/527) | Implement spec 059 command dispatch | Blocked |
| [110](https://github.com/traverse-framework/reference-apps/issues/110) | traverse-starter.pipeline multi-capability workflow | Done |
| [111](https://github.com/traverse-framework/reference-apps/issues/111) | doc-approval.pipeline multi-capability workflow | Done |
| [112](https://github.com/traverse-framework/reference-apps/issues/112) | doc-approval manifests | Done |
| [113](https://github.com/traverse-framework/reference-apps/issues/113) | Embed runtime — web-react | Done |
| [114](https://github.com/traverse-framework/reference-apps/issues/114) | Embed runtime — Swift (iOS + macOS) | Blocked |
| [115](https://github.com/traverse-framework/reference-apps/issues/115) | Embed runtime — Android | Blocked |
| [116](https://github.com/traverse-framework/reference-apps/issues/116) | Embed runtime — Windows | Blocked |
| [117](https://github.com/traverse-framework/reference-apps/issues/117) | Embed runtime — Linux + CLI | Done (this PR) |
| [118](https://github.com/traverse-framework/reference-apps/issues/118) | embedded_smoke.sh CI gate | Future |
| [58](https://github.com/traverse-framework/reference-apps/issues/58), [72](https://github.com/traverse-framework/reference-apps/issues/72) | Shared Swift embedded host package | Blocked |
| [59](https://github.com/traverse-framework/reference-apps/issues/59), [73](https://github.com/traverse-framework/reference-apps/issues/73) | Shared Rust embedded host package | Blocked |

## Validation (Phase 3 complete)

When Phase 3 is done:

1. Install/build any platform client **without** starting `traverse-cli serve`
2. Submit input → multi-capability workflow runs → all output fields render
3. `bash scripts/ci/embedded_smoke.sh` passes (to be added) on CI agents with embedded host support
4. No business field computation in UI diff review
5. Manifests in `manifests/` reference WASM digests bundled in app artifacts
