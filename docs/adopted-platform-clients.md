# Adopted Traverse platform clients

This repository is the **canonical home** for checked-in application UI, platform client demos, and starter/reference source previously maintained under Traverse `apps/`.

## Two-tier layout (primary vs secondary)

| Tier | Apps | What “done” means |
|---|---|---|
| **Primary product shells** | `traverse-starter`, `doc-approval`, `meeting-notes` | Embedded (or showcase-track embed) production path; digest pin; SDK doubles; production DoD on PRs; Linux-runnable slices of `embedded_smoke` are merge-blocking |
| **Adopted / secondary** | paths in the table below + `apps/llm-mcp-reference/` | Lighter maintenance; demo/kit smokes only; **not** hard-fail slices of `embedded_smoke` |
| **Debugger** | `trace-explorer` | Not a product shell — embedded Trace API companion (`embed-trace-explorer`) |

Do **not** copy retired Expedition demo patterns into primary shells; use primary product shells or `browser-consumer` / youaskm3 kit guidance.

Ownership boundary (Traverse [#703](https://github.com/traverse-framework/Traverse/issues/703)):

| Former Traverse path | Owner | Destination here |
|---|---|---|
| `apps/android-demo/` | Reference Apps | **Retired** 2026-08-12 (`retire-android-demo`) — use primary Android Compose shells |
| `apps/browser-consumer/` | Reference Apps | [`apps/browser-consumer/`](../apps/browser-consumer/) |
| `apps/macos-demo/` | Reference Apps | **Retired** 2026-08-12 (`retire-macos-demo`) — use primary SwiftUI shells |
| `apps/react-demo/` | Reference Apps | **Retired** 2026-08-12 (`retire-react-demo`) — use primary Web shells / `browser-consumer` |
| `apps/youaskm3-starter-kit/` | Reference Apps | [`apps/youaskm3-starter-kit/`](../apps/youaskm3-starter-kit/) |
| `apps/llm-mcp-reference/` (new) | Reference Apps | [`apps/llm-mcp-reference/`](../apps/llm-mcp-reference/) — LLM MCP façades; [`llm-reference-apps-plan.md`](llm-reference-apps-plan.md) |
| Runtime fixtures / manifests | Traverse | `examples/` in Traverse (not adopted) |

Shared fixture for remaining native demos: [`fixtures/expedition-runtime-session.json`](../fixtures/expedition-runtime-session.json).

## Validation commands (secondary / adopted)

| Artifact | Command |
|---|---|
| Android demo | `bash scripts/ci/android_demo_smoke.sh` |
| youaskm3 starter | `bash scripts/ci/youaskm3_starter_kit_smoke.sh` |
| LLM MCP reference | `bash scripts/ci/llm_mcp_reference_smoke.sh` |
| Browser consumer live | `TRAVERSE_REPO=… bash scripts/ci/browser_consumer_package_smoke.sh` |

These commands prove secondary kits still load; they do **not** substitute for `bash scripts/ci/embedded_smoke.sh` on primary shells.

All adopted artifacts use public Traverse surfaces (browser adapter CLI, published consumer-bundle docs). No private runtime crate imports.
