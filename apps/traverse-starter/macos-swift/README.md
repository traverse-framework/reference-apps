# traverse-starter (macOS SwiftUI)

**Runtime mode: Embedded** — uses `TraverseEmbedder` (WASM runtime host) via shared [`TraverseCore`](../TraverseCore/). No HTTP sidecar required. Implements [#114](https://github.com/traverse-framework/reference-apps/issues/114).

Native macOS client for the `traverse-starter` reference app.

## Prerequisites

- **Xcode 16+** on macOS
- Bundle sync (first time and after Traverse updates):

```bash
TRAVERSE_REPO=/tmp/Traverse bash scripts/ci/sync_swift_starter_bundle.sh
```

## Build and run

```bash
cd apps/traverse-starter/macos-swift
xcodebuild -scheme TraverseStarterMac -destination 'platform=macOS' build test
```

Package unit tests:

```bash
cd apps/traverse-starter/TraverseCore && swift test
```

Or open `TraverseStarterMac.xcodeproj` in Xcode and run on macOS 14+.

## Configuration

Open **TraverseStarterMac → Settings…** (⌘,) to configure:

- **Workspace** — defaults to `local-default`

Runtime URL is no longer required. The embedded runtime is bundled in the app.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘↩ | Submit note |
| ⌘R | Reset output |
| ⌘, | Preferences (workspace) |

## Architecture

| File / package | Role |
|---|---|
| [`../TraverseCore/`](../TraverseCore/) | Shared Swift package: `EmbeddedRuntime`, `AppStateViewModel`, output parsing |
| `ContentView.swift` | Main window — input, output, toolbar status strip |
| `PreferencesView.swift` | Workspace settings (Settings scene) |
| `AppDelegate.swift` | `NSApplicationDelegate` lifecycle |
| `AppSettings.swift` | UserDefaults (workspace only) |
| `Resources/bundles/traverse-starter/` | Bundled WASM runtime + manifests |

UI renders runtime-owned fields only — no business logic in the shell.
