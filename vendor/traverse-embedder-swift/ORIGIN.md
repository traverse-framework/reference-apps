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
