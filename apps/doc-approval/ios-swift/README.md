# doc-approval (iOS)

**Runtime mode: HTTP sidecar (interim)** — shared `DocApprovalCore` HTTP command dispatch + SSE. Embedded WASM cutover is tracked in [#114](https://github.com/traverse-framework/reference-apps/issues/114). Requires `traverse-cli serve`.

Native iOS submitter client for the **doc-approval** reference app.

## Prerequisites

- Xcode 16+
- Traverse HTTP sidecar locally (`cargo run -p traverse-cli -- serve`)

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
