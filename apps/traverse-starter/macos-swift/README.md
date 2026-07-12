# traverse-starter (macOS SwiftUI)

Native macOS client for the `traverse-starter` reference app. Uses shared [`TraverseCore`](../TraverseCore/) for HTTP command dispatch + SSE app state (same pattern as `web-react` / `ios-swift`).

## Prerequisites

- **Xcode 16+** on macOS
- **Traverse runtime** running locally

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

## Runtime URL configuration

Open **TraverseStarterMac → Settings…** (⌘,) and set:

- **Runtime URL** — default `http://127.0.0.1:8787` (auto-filled from `.traverse/server.json` when present)
- **Workspace** — default `local-default`

Values persist in UserDefaults.

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

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘↩ | Submit note |
| ⌘R | Reset output |
| ⌘, | Preferences (runtime URL + workspace) |

## Architecture

| File / package | Role |
|---|---|
| [`../TraverseCore/`](../TraverseCore/) | Shared Swift package: client, SSE, `AppStateViewModel` |
| `ContentView.swift` | Main window — input, output, toolbar health strip |
| `PreferencesView.swift` | Runtime settings (Settings scene) |
| `AppDelegate.swift` | `NSApplicationDelegate` lifecycle |
| `AppSettings.swift` | UserDefaults + optional `ServerDiscovery` |

UI renders runtime-owned fields only — no business logic in the shell.
