#!/usr/bin/env bash
# Sync doc-approval bundle into Swift iOS + macOS Resources for RuntimeTraverseEmbedder.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
MANIFEST_SRC="$REPO_ROOT/manifests/doc-approval"
DESTS=(
  "$REPO_ROOT/apps/doc-approval/ios-swift/DocApproval/Resources/bundles/doc-approval"
  "$REPO_ROOT/apps/doc-approval/macos-swift/DocApprovalMac/Resources/bundles/doc-approval"
)

if [ ! -f "$TRAVERSE_REPO/runtime/runtime.wasm" ]; then
  echo "FAIL: TRAVERSE_REPO runtime missing: $TRAVERSE_REPO/runtime/runtime.wasm"
  exit 1
fi

for DEST in "${DESTS[@]}"; do
  rm -rf "$DEST"
  mkdir -p "$DEST/runtime"
  mkdir -p "$DEST/components/analyze" "$DEST/components/recommend"
  cp "$MANIFEST_SRC/app.manifest.json" "$DEST/"
  cp "$MANIFEST_SRC/components/analyze/component.manifest.json" "$DEST/components/analyze/"
  cp "$MANIFEST_SRC/components/recommend/component.manifest.json" "$DEST/components/recommend/"
  cp "$TRAVERSE_REPO/runtime/runtime.wasm" "$DEST/runtime/"
  cp "$TRAVERSE_REPO/runtime/runtime-release.json" "$DEST/runtime/"
  echo "OK: synced Swift doc-approval bundle → $DEST"
done
