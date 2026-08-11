# Spec 003: Loop WF1 Multi-OS Reference App

**Created**: 2026-08-11  
**Status**: Approved  
**Approved**: 2026-08-11 (session authorization — event parity + Loop workstream)  
**Decision log**: [`../../decision-log.md`](../../decision-log.md) (2026-08-11)  
**Product source**: Loop Capability Package v2 (contracts + product/workflow docs)

## Purpose

Define Loop as a first-class App-References product shell implementing **WF1 – Ingest & Extract Action Items**, on all seven OS targets, consuming digest-pinned Traverse registry artifacts only.

## Product positioning (locked)

Loop is the **follow-through layer for meetings**. WF1 is the first reference slice (extract → normalize → authorize, with human review). WF3 (nudge engine) is explicitly out of scope for this spec.

## Architecture boundary

- App-References: thin clients under `apps/loop/` for web, macOS, iOS, Android, Windows, Linux GTK, CLI
- Traverse / registry: capability WASM, workflow composition, digests
- No fake workflow registration; no business extraction logic in UI

## Platforms (required)

Same bar as `traverse-starter` / `doc-approval`:

| Target | Client path (expected) |
|---|---|
| Web | `apps/loop/web-react/` |
| macOS | `apps/loop/macos-swift/` |
| iOS | `apps/loop/ios-swift/` |
| Android | `apps/loop/android-compose/` |
| Windows | `apps/loop/windows-winui/` |
| Linux GTK | `apps/loop/linux-gtk/` |
| CLI | `apps/loop/cli-rust/` |

## Functional requirements

- **FR-001**: App id `loop` with `app.manifest.json` including `state_machine` and `list_context_fields` for WF1 review/results UX.
- **FR-002**: Production path uses public platform embedders (embedded mode); digest-pinned `runtime/runtime.wasm` and product agents via existing sync scripts pattern.
- **FR-003**: UI presentation states conform to Specs 001 and 002.
- **FR-004**: Human review step renders only runtime-provided candidate fields; accept/reject/edit actions submit back through runtime/public APIs — UI does not invent confidence thresholds.
- **FR-005**: README + platform table + design-language reference row updated when shipping.
- **FR-006**: Unit tests use embedder test doubles only for host logic; conformance fixtures reused from the shared harness.

## Blocked until

Digest-pinned WF1 capabilities/workflow are published to the Traverse registry (at minimum the contracts referenced by Loop package WF1, including `core.extract-action-items` 1.1.0 path, normalize, authorize, and meeting ingest dependency as applicable). Tracked by Project 2 ticket `loop-wf1-registry-deps`.

## Non-goals

- WF2–WF5 implementation in this spec
- Implementing WASM capabilities inside App-References
- Using recorded fixtures as the primary demo path (fixtures are tests only)

## Validation

- Platform READMEs document **Runtime mode: Embedded**
- CI gates for each shipped platform match starter/doc-approval expectations
- Spec 001/002 conformance green on each Loop client that has a unit-test toolchain in CI
