# TraverseCore

Shared Swift package for traverse-starter iOS and macOS shells.

- `EmbeddedHost` — `RuntimeTraverseEmbedder` / `InMemoryTraverseEmbedder` boundary (Spec 068 / 071)
- `AppStateViewModel` — Zone 1 Ready/Unavailable + submit/reset
- `TraverseStarterOutput` / parsers — runtime-owned field decoding only

Vendored SDK: `vendor/traverse-embedder-swift/`.

```bash
cd apps/traverse-starter/TraverseCore && swift test
```
