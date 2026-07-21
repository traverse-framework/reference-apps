# Vendored from traverse-framework/Traverse packages/swift/TraverseEmbedder (specs 068 / 071 / 072).

Refresh:
```bash
export TRAVERSE_REPO=/path/to/Traverse
rm -rf vendor/traverse-embedder-swift/Sources vendor/traverse-embedder-swift/Package.swift
cp -a "$TRAVERSE_REPO/packages/swift/TraverseEmbedder/Package.swift" vendor/traverse-embedder-swift/
cp -a "$TRAVERSE_REPO/packages/swift/TraverseEmbedder/README.md" vendor/traverse-embedder-swift/
cp -a "$TRAVERSE_REPO/packages/swift/TraverseEmbedder/Sources" vendor/traverse-embedder-swift/
```

The `TraverseSwiftHost` XCFramework is still resolved from the Traverse release URL in Package.swift.

Pinned runtime digest lives in synced app bundles (`runtime/runtime-release.json`).
Single pin source: `$TRAVERSE_REPO/runtime/runtime-release.json` (must match `runtime.wasm` sha256).

After a Traverse runtime release, refresh this vendor tree **and** re-sync native bundles:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_swift_starter_bundle.sh
bash scripts/ci/sync_swift_doc_approval_bundle.sh
```

See [`docs/runtime-bundle-sync.md`](../../docs/runtime-bundle-sync.md).
