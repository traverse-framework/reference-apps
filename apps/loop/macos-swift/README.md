# loop (macOS SwiftUI)

**Runtime mode: Embedded** — in-process `TraverseEmbedder` (Swift) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` required.

## Sync bundle

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_swift_loop_bundle.sh
```

Destination: `LoopMac/Resources/bundles/loop/`

## Build / run

Open `LoopMac.xcodeproj` in Xcode → Run.

Shared host + tests: [`../LoopCore/`](../LoopCore/)

```bash
cd apps/loop/LoopCore && swift test
```
