# doc-approval (macOS)

**Runtime mode: HTTP sidecar (interim)** — shared `DocApprovalCore` HTTP command dispatch + SSE. Embedded WASM cutover is tracked in [#114](https://github.com/traverse-framework/reference-apps/issues/114). Requires `traverse-cli serve`.

Native macOS submitter client for the **doc-approval** reference app.

## Prerequisites

- Xcode 16+
- Traverse HTTP sidecar locally (`cargo run -p traverse-cli -- serve`)

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
