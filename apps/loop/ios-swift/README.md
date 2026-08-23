# loop (iOS SwiftUI)

**Runtime mode: Embedded** — in-process `TraverseEmbedder` (Swift) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` required.

## Sync bundle

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_swift_loop_bundle.sh
```

Destination: `Loop/Resources/bundles/loop/`

## Build / run

Open `Loop.xcodeproj` in Xcode → Run (Simulator).

Shared host + tests: [`../LoopCore/`](../LoopCore/)

```bash
cd apps/loop/LoopCore && swift test
```
