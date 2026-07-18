# traverse-starter (iOS SwiftUI)

**Runtime mode: HTTP sidecar (interim)** — uses shared [`TraverseCore`](../TraverseCore/) for HTTP command dispatch + SSE. Embedded WASM cutover is tracked in [#114](https://github.com/traverse-framework/reference-apps/issues/114). Requires `traverse-cli serve`.

Native iOS client for the `traverse-starter` reference app.

## Prerequisites

- **Xcode 16+** with iOS 17 simulator
- **Traverse HTTP sidecar** running locally or on your LAN

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

## Runtime URL configuration

1. Open the app in the simulator
2. Tap **Settings**
3. Set **Runtime URL** (default `http://127.0.0.1:8787`) and **Workspace** (`local-default`)
4. Save

Settings persist in UserDefaults. For a physical device on Wi‑Fi, use your Mac's LAN IP instead of `127.0.0.1`.

## Build and run

```bash
cd apps/traverse-starter/ios-swift
xcodebuild -scheme TraverseStarter \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build test
```

Package unit tests (preferred for client/SSE logic):

```bash
cd apps/traverse-starter/TraverseCore && swift test
```

Or open `TraverseStarter.xcodeproj` in Xcode and run on an iOS 17+ simulator.

## Architecture

| File / package | Role |
|---|---|
| [`../TraverseCore/`](../TraverseCore/) | Shared Swift package: `TraverseClient`, `AppStateViewModel`, output parsing, SSE |
| `AppSettings.swift` | UserDefaults persistence + app id |
| `ContentView.swift` | Three-zone UI (runtime / input / output) |
| `SettingsView.swift` | Runtime URL + workspace editor |

UI renders runtime-owned fields only — no business logic in the shell.
