# doc-approval (iOS)

**Runtime mode: Embedded** — uses `TraverseEmbedder` (WASM runtime host) via shared [`DocApprovalCore`](../DocApprovalCore/). No HTTP sidecar required. Implements [#114](https://github.com/traverse-framework/reference-apps/issues/114).

Native iOS submitter client for the **doc-approval** reference app.

## Prerequisites

- Xcode 16+
- Bundle sync (first time and after Traverse updates):

```bash
TRAVERSE_REPO=/tmp/Traverse bash scripts/ci/sync_swift_doc_approval_bundle.sh
```

## Open and run

```bash
open apps/doc-approval/ios-swift/DocApproval.xcodeproj
```

Settings (gear) configures workspace (default `local-default`).

## Architecture

| Path | Role |
|---|---|
| `../DocApprovalCore` | Shared embedded host client, `AppStateViewModel`, output parsing |
| `ContentView.swift` | SwiftUI shell — input, output, runtime strip |
| `AppSettings.swift` | UserDefaults for workspace |
| `Resources/bundles/doc-approval/` | Bundled WASM runtime + manifests |

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
