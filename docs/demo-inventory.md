# Demo upgrade-or-retire inventory

Governing: Spec [`004-demo-upgrade-or-retire`](specs/004-demo-upgrade-or-retire/spec.md), ADR [`0004`](adr/0004-demo-retire-delete-with-scrub.md).

Reconciled against `find apps -maxdepth 1 -type d` on 2026-08-11. Primaries are listed for completeness; Spec 004 actions apply only to non-primaries.

| Path | Classification | Rationale | Follow-up ticket-id |
|---|---|---|---|
| `apps/traverse-starter` | already-primary | Production multi-OS reference shell | — |
| `apps/meeting-notes` | already-primary | Production multi-OS product shell | — |
| `apps/doc-approval` | already-primary | Production multi-OS product shell | — |
| `apps/trace-explorer` | already-primary | Debugger companion (web-only by design) | — |
| `apps/loop` | already-primary | WF1 seven-OS product shell | — |
| `apps/react-demo` | retire (done) | Removed 2026-08-12; primaries own Web UX; browser-consumer owns browser façade | `retire-react-demo` |
| `apps/android-demo` | retire (done) | Removed 2026-08-12; superseded by primary Android Compose shells | `retire-android-demo` |
| `apps/macos-demo` | retire (done) | Removed 2026-08-12; superseded by primary SwiftUI shells | `retire-macos-demo` |
| `apps/browser-consumer` | upgrade (done) | Specs 001/002; no `react-demo` dependency | `upgrade-browser-consumer-events` |
| `apps/youaskm3-starter-kit` | upgrade (done) | Embedded path + Specs 001/002 vocabulary | `upgrade-youaskm3-starter-kit-events` |
| `apps/llm-mcp-reference` | upgrade (done) | Spec 001/002 presentation vocabulary in workflow docs | `upgrade-llm-mcp-reference-events` |

## Follow-up board items

Shipped. Do not treat this table as live status — Project 2 is SoT.

| ticket-id | Outcome |
|---|---|
| `retire-react-demo` | Done |
| `retire-android-demo` | Done |
| `retire-macos-demo` | Done |
| `upgrade-browser-consumer-events` | Done |
| `upgrade-youaskm3-starter-kit-events` | Done |
| `upgrade-llm-mcp-reference-events` | Done |

## Status

Inventory plus follow-up tickets are complete. New-app author: [`new-app-author.md`](new-app-author.md). Kit-runner personas: [`kit-runner-persona.md`](kit-runner-persona.md).
