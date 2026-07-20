# DocApprovalCore

Shared Swift package for doc-approval iOS and macOS shells.

- `EmbeddedHost` — `RuntimeTraverseEmbedder` / `InMemoryTraverseEmbedder` boundary
- `AppStateViewModel` — Zone 1 Ready/Unavailable + submit/reset
- `DocApprovalOutput` — runtime-owned field decoding only

```bash
cd apps/doc-approval/DocApprovalCore && swift test
```
