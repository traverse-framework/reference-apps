# traverse-starter (macOS SwiftUI)

Native macOS client for the `traverse-starter` reference app. Phase 1 uses HTTP polling against the public Traverse HTTP/JSON API (spec 033) — same flow as `web-react` and `ios-swift`.

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

- **Runtime URL** — default `http://127.0.0.1:8787`
- **Workspace** — default `local-default`

Values persist in UserDefaults.

## Build and run

```bash
cd apps/traverse-starter/macos-swift
xcodebuild -scheme TraverseStarterMac -destination 'platform=macOS' build test
```

Or open `TraverseStarterMac.xcodeproj` in Xcode and run on macOS 14+.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘↩ | Submit note |
| ⌘R | Reset output |
| ⌘, | Preferences (runtime URL + workspace) |

## Architecture

| File | Role |
|---|---|
| `TraverseClient.swift` | URLSession HTTP client (copied from ios-swift; shared package in #58) |
| `ExecutionViewModel.swift` | MVVM polling state machine |
| `ContentView.swift` | Main window — input, output, toolbar health strip |
| `PreferencesView.swift` | Runtime settings (Settings scene) |
| `AppDelegate.swift` | `NSApplicationDelegate` lifecycle |

## Phase 2 (not implemented)

SSE subscription when Traverse ships [#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527). Extract shared `TraverseCore` with ios-swift ([#58](https://github.com/traverse-framework/reference-apps/issues/58)).

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
