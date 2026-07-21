# Vendored from traverse-framework/Traverse packages/dotnet/TraverseEmbedder @ 0.1.0 (specs 068 / 071 / 072).

Refresh:
```bash
export TRAVERSE_REPO=/path/to/Traverse
rm -rf vendor/traverse-embedder-dotnet/TraverseEmbedder
cp -a "$TRAVERSE_REPO/packages/dotnet/TraverseEmbedder/TraverseEmbedder" vendor/traverse-embedder-dotnet/
cp "$TRAVERSE_REPO/packages/dotnet/TraverseEmbedder/README.md" vendor/traverse-embedder-dotnet/README.md
```

Pinned runtime digest lives in synced app bundles (`runtime/runtime-release.json`).
Single pin source: `$TRAVERSE_REPO/runtime/runtime-release.json` (must match `runtime.wasm` sha256).

After a Traverse runtime release, refresh this vendor tree **and** re-sync WinUI bundles:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_winui_starter_bundle.sh
bash scripts/ci/sync_winui_doc_approval_bundle.sh
```

See [`docs/runtime-bundle-sync.md`](../../docs/runtime-bundle-sync.md).
