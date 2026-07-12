# doc-approval (macOS)

Native macOS submitter client for the **doc-approval** reference app. Uses shared `DocApprovalCore` for HTTP command dispatch and SSE app-state events.

## Prerequisites

- Xcode 16+
- Traverse runtime locally (`cargo run -p traverse-cli -- serve`)

## Open and run

```bash
open apps/doc-approval/macos-swift/DocApprovalMac.xcodeproj
```

Preferences (⌘,) configures runtime URL and workspace. On first launch, macOS may discover `.traverse/server.json` via `SessionDiscovery`.

## Architecture

| Path | Role |
|---|---|
| `../DocApprovalCore` | Shared HTTP/SSE client, `AppStateViewModel`, session listing |
| `ContentView.swift` | SwiftUI shell — sidebar + document/output |
| `AppSettings.swift` | UserDefaults for URL / workspace |

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
