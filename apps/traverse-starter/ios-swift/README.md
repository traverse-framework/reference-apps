# traverse-starter (iOS SwiftUI)

**Runtime mode: Embedded** — in-process `TraverseEmbedder` (Swift) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` required.

## Prerequisites

- Xcode 16+ / iOS 17+
- Bundled assets under `TraverseStarter/Resources/bundles/traverse-starter/`

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_swift_starter_bundle.sh
```

## Build and test

Open `TraverseStarter.xcodeproj` in Xcode, or:

```bash
cd apps/traverse-starter/TraverseCore && swift test
cd apps/traverse-starter/ios-swift && xcodebuild -scheme TraverseStarter -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Shared host logic lives in [`../TraverseCore/`](../TraverseCore/) (`EmbeddedHost`, `AppStateViewModel`).
