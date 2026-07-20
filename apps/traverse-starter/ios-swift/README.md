# traverse-starter (iOS SwiftUI)

**Runtime mode: Embedded** — uses `TraverseEmbedder` (WASM runtime host) via shared [`TraverseCore`](../TraverseCore/). No HTTP sidecar required. Implements [#114](https://github.com/traverse-framework/reference-apps/issues/114).

Native iOS client for the `traverse-starter` reference app.

## Prerequisites

- **Xcode 16+** with iOS 17 simulator
- Bundle sync (first time and after Traverse updates):

```bash
TRAVERSE_REPO=/tmp/Traverse bash scripts/ci/sync_swift_starter_bundle.sh
```

## Build and run

```bash
cd apps/traverse-starter/ios-swift
xcodebuild -scheme TraverseStarter \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build test
```

Package unit tests (preferred for embedded host logic):

```bash
cd apps/traverse-starter/TraverseCore && swift test
```

Or open `TraverseStarter.xcodeproj` in Xcode and run on an iOS 17+ simulator.

## Configuration

Open **Settings** (gear icon) to configure:

- **Workspace** — defaults to `local-default`

Runtime URL is no longer required. The embedded runtime is bundled in the app.

## Architecture

| File / package | Role |
|---|---|
| [`../TraverseCore/`](../TraverseCore/) | Shared Swift package: `EmbeddedRuntime`, `AppStateViewModel`, output parsing |
| `AppSettings.swift` | UserDefaults persistence (workspace only) |
| `ContentView.swift` | Three-zone UI (runtime / input / output) |
| `SettingsView.swift` | Workspace editor |
| `Resources/bundles/traverse-starter/` | Bundled WASM runtime + manifests |

UI renders runtime-owned fields only — no business logic in the shell.
