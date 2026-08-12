# Demo upgrade-or-retire inventory

Governing: Spec [`004-demo-upgrade-or-retire`](specs/004-demo-upgrade-or-retire/spec.md), ADR [`0004`](adr/0004-demo-retire-delete-with-scrub.md).

Reconciled against `find apps -maxdepth 1 -type d` on 2026-08-11. Primaries are listed for completeness; Spec 004 actions apply only to non-primaries.

| Path | Classification | Rationale | Follow-up ticket-id |
|---|---|---|---|
| `apps/traverse-starter` | already-primary | Production multi-OS reference shell | — |
| `apps/meeting-notes` | already-primary | Production multi-OS product shell | — |
| `apps/doc-approval` | already-primary | Production multi-OS product shell | — |
| `apps/trace-explorer` | already-primary | Debugger companion (web-only by design) | — |
| `apps/react-demo` | retire (done) | Removed 2026-08-12; primaries own Web UX; browser-consumer owns browser façade | `retire-react-demo` |
| `apps/android-demo` | retire (done) | Removed 2026-08-12; superseded by primary Android Compose shells | `retire-android-demo` |
| `apps/macos-demo` | retire (done) | Removed 2026-08-12; superseded by primary SwiftUI shells | `retire-macos-demo` |
| `apps/android-demo` | retire | Expedition Android sample; superseded by primary Android Compose shells | `retire-android-demo` |
| `apps/macos-demo` | retire (done) | Removed 2026-08-12; superseded by primary SwiftUI shells | `retire-macos-demo` |
| `apps/browser-consumer` | upgrade | Keep as downstream browser façade; align to Specs 001/002 and stop depending on `react-demo` once that path retires | `upgrade-browser-consumer-events` |
| `apps/youaskm3-starter-kit` | upgrade | Keep as downstream getting-started kit; point at embedded/public surfaces + Specs 001/002 vocabulary | `upgrade-youaskm3-starter-kit-events` |
| `apps/llm-mcp-reference` | upgrade | Active secondary LLM MCP façades; keep and align workflow docs to event presentation contract | `upgrade-llm-mcp-reference-events` |

## Follow-up board items (Future until inventory merges)

| ticket-id | Project 2 item |
|---|---|
| `retire-react-demo` | `PVTI_lADOEbiBt84BbzAzzg2Lkhk` |
| `retire-android-demo` | `PVTI_lADOEbiBt84BbzAzzg2Lkik` |
| `retire-macos-demo` | `PVTI_lADOEbiBt84BbzAzzg2Lkjg` |
| `upgrade-browser-consumer-events` | `PVTI_lADOEbiBt84BbzAzzg2LklM` |
| `upgrade-youaskm3-starter-kit-events` | `PVTI_lADOEbiBt84BbzAzzg2Lkms` |
| `upgrade-llm-mcp-reference-events` | `PVTI_lADOEbiBt84BbzAzzg2Lkno` |

## Status

Inventory only — no apps removed in this document’s landing PR. Follow-up Project 2 tickets start as `Future` until this inventory merges (Spec 004 validation). Retire PRs must scrub CI/docs in the same change and add a README **Retired demos** note (ADR-0004).
