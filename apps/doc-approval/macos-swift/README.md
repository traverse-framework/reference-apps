# doc-approval (macOS SwiftUI)

**Runtime mode: Embedded** — in-process `TraverseEmbedder` (Swift) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` required.

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_swift_doc_approval_bundle.sh
```

Shared host: [`../DocApprovalCore/`](../DocApprovalCore/).
