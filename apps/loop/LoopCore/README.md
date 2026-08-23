# LoopCore

Shared Swift package for loop iOS and macOS shells.

- `EmbeddedHost` — `RuntimeTraverseEmbedder` / `InMemoryTraverseEmbedder` boundary
- `AppStateViewModel` — Zone 1 Ready/Unavailable + submit/reset
- `LoopOutput` — runtime-owned field decoding only

```bash
cd apps/loop/LoopCore && swift test
```
