# doc-approval (iOS SwiftUI)

Native iOS submitter client for the **doc-approval** reference app. Phase 1 uses HTTP polling against the public Traverse HTTP/JSON API (spec 033) — same flow as `web-react`.

## Prerequisites

- **Xcode 16+** with iOS 17 simulator
- **Traverse runtime** running locally or on your LAN

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

The doc-approval capability must be registered in the runtime before execute calls succeed.

## Runtime URL configuration

1. Open the app in the simulator
2. Tap **Settings**
3. Set **Runtime URL** (default `http://127.0.0.1:8787`) and **Workspace** (`local-default`)
4. Save

Settings persist in UserDefaults. For a physical device on Wi‑Fi, use your Mac's LAN IP instead of `127.0.0.1`.

## Build and run

```bash
cd apps/doc-approval/ios-swift
xcodebuild -scheme DocApproval \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build test
```

Or open `DocApproval.xcodeproj` in Xcode and run on an iOS 17+ simulator.

## Architecture

| File | Role |
|---|---|
| `TraverseClient.swift` | URLSession HTTP client (execute, poll, trace, health) |
| `ExecutionViewModel.swift` | MVVM state machine: idle → loading → polling → done |
| `ContentView.swift` | Main UI — runtime strip, document input, analysis fields |
| `SettingsView.swift` | Runtime URL + workspace |
| `AppSettings.swift` | UserDefaults persistence |

The UI renders runtime-provided analysis fields only — no business logic in the client.

## Phase 2 (not implemented)

When Traverse ships SSE state subscription ([#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527)), replace polling with SSE, add approver surface, and share `DocApprovalCore` with macOS (see [#72](https://github.com/traverse-framework/reference-apps/issues/72)).
