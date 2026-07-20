#!/usr/bin/env bash
# Sync traverse-starter bundle into Swift iOS + macOS Resources for RuntimeTraverseEmbedder.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
MANIFEST_SRC="$REPO_ROOT/manifests/traverse-starter"
DESTS=(
  "$REPO_ROOT/apps/traverse-starter/ios-swift/TraverseStarter/Resources/bundles/traverse-starter"
  "$REPO_ROOT/apps/traverse-starter/macos-swift/TraverseStarterMac/Resources/bundles/traverse-starter"
)

if [ ! -f "$TRAVERSE_REPO/runtime/runtime.wasm" ]; then
  echo "FAIL: TRAVERSE_REPO runtime missing: $TRAVERSE_REPO/runtime/runtime.wasm"
  exit 1
fi

for DEST in "${DESTS[@]}"; do
  rm -rf "$DEST"
  mkdir -p "$DEST/runtime"
  mkdir -p "$DEST/components/validate" "$DEST/components/process" "$DEST/components/summarize"
  cp "$MANIFEST_SRC/app.manifest.json" "$DEST/"
  cp "$MANIFEST_SRC/components/validate/component.manifest.json" "$DEST/components/validate/"
  cp "$MANIFEST_SRC/components/process/component.manifest.json" "$DEST/components/process/"
  cp "$MANIFEST_SRC/components/summarize/component.manifest.json" "$DEST/components/summarize/"
  cp "$TRAVERSE_REPO/runtime/runtime.wasm" "$DEST/runtime/"
  cp "$TRAVERSE_REPO/runtime/runtime-release.json" "$DEST/runtime/"
  echo "OK: synced Swift starter bundle → $DEST"
done
