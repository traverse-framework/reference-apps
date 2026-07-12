# doc-approval (iOS)

Native iOS submitter client for the **doc-approval** reference app. Uses shared `DocApprovalCore` for HTTP command dispatch and SSE app-state events.

## Prerequisites

- Xcode 16+
- Traverse runtime locally (`cargo run -p traverse-cli -- serve`)

## Open and run

```bash
open apps/doc-approval/ios-swift/DocApproval.xcodeproj
```

Settings (gear) configures runtime URL and workspace (defaults `http://127.0.0.1:8787` / `local-default`).

## Architecture

| Path | Role |
|---|---|
| `../DocApprovalCore` | Shared HTTP/SSE client, `AppStateViewModel`, session listing |
| `ContentView.swift` | SwiftUI shell — input, output, runtime strip |
| `AppSettings.swift` | UserDefaults for URL / workspace |

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
