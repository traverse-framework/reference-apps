# traverse-starter (macOS SwiftUI)

**Runtime mode: Embedded** — in-process `TraverseEmbedder` (Swift) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` required.

## Prerequisites

- Xcode 16+ / macOS 14+
- Bundled assets under `TraverseStarterMac/Resources/bundles/traverse-starter/`

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_swift_starter_bundle.sh
```

## Build and test

Open `TraverseStarterMac.xcodeproj` in Xcode, or:

```bash
cd apps/traverse-starter/TraverseCore && swift test
cd apps/traverse-starter/macos-swift && xcodebuild -scheme TraverseStarterMac -destination 'platform=macOS' test
```

Shared host logic lives in [`../TraverseCore/`](../TraverseCore/) (`EmbeddedHost`, `AppStateViewModel`).
