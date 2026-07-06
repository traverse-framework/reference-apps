# doc-approval (macOS SwiftUI)

Native macOS submitter client for the **doc-approval** reference app. Phase 1 uses HTTP polling against the public Traverse HTTP/JSON API (spec 033) — same flow as `web-react` and `ios-swift`.

## Prerequisites

- **Xcode 16+** on macOS 14+
- **Traverse runtime** running locally

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

The doc-approval capability must be registered in the runtime before execute calls succeed.

## Runtime URL configuration

Use **DocApprovalMac → Settings** (⌘,) to set **Runtime URL** (default `http://127.0.0.1:8787`) and **Workspace** (`local-default`). Settings persist in UserDefaults.

## Build and run

```bash
cd apps/doc-approval/macos-swift
xcodebuild -scheme DocApprovalMac -destination 'platform=macOS' build test
```

Or open `DocApprovalMac.xcodeproj` in Xcode.

## Architecture

| File | Role |
|---|---|
| `TraverseClient.swift` | URLSession HTTP client (execute, poll, trace, health) |
| `ExecutionViewModel.swift` | MVVM state machine: idle → loading → polling → done |
| `ContentView.swift` | Split view — sidebar, document input, analysis output |
| `PreferencesView.swift` | Runtime URL + workspace (Settings window) |
| `AppSettings.swift` | UserDefaults persistence |

The UI renders runtime-provided analysis fields only — no business logic in the client.

## Phase 2 (not implemented)

When Traverse ships SSE and session listing ([#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527), [#537](https://github.com/traverse-framework/Traverse/issues/537)), replace polling with SSE, add approver surface, and share `DocApprovalCore` with ios-swift (see [#72](https://github.com/traverse-framework/reference-apps/issues/72)).
