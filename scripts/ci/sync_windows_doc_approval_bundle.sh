#!/usr/bin/env bash
# Sync doc-approval application bundle into WinUI Assets for RuntimeTraverseEmbedder.
# Requires TRAVERSE_REPO (or sibling ../Traverse) with runtime/runtime.wasm.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
DEST="$REPO_ROOT/apps/doc-approval/windows-winui/DocApproval/Assets/bundles/doc-approval"
MANIFEST_SRC="$REPO_ROOT/manifests/doc-approval"

if [ ! -f "$TRAVERSE_REPO/runtime/runtime.wasm" ]; then
  echo "FAIL: TRAVERSE_REPO runtime missing: $TRAVERSE_REPO/runtime/runtime.wasm"
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST/runtime"
mkdir -p "$DEST/components/analyze" "$DEST/components/recommend"
mkdir -p "$DEST/_traverse/examples/doc-approval"
mkdir -p "$DEST/_traverse/workflows/examples/doc-approval"
mkdir -p "$DEST/_traverse/contracts/examples/doc-approval"

cp "$MANIFEST_SRC/app.manifest.json" "$DEST/"
cp "$MANIFEST_SRC/components/analyze/component.manifest.json" "$DEST/components/analyze/"
cp "$MANIFEST_SRC/components/recommend/component.manifest.json" "$DEST/components/recommend/"

cp "$TRAVERSE_REPO/runtime/runtime.wasm" "$DEST/runtime/"
cp "$TRAVERSE_REPO/runtime/runtime-release.json" "$DEST/runtime/"

if [ -d "$TRAVERSE_REPO/examples/doc-approval" ]; then
  cp -a "$TRAVERSE_REPO/examples/doc-approval/." "$DEST/_traverse/examples/doc-approval/"
fi
if [ -d "$TRAVERSE_REPO/workflows/examples/doc-approval" ]; then
  cp -a "$TRAVERSE_REPO/workflows/examples/doc-approval/." "$DEST/_traverse/workflows/examples/doc-approval/"
fi
if [ -d "$TRAVERSE_REPO/contracts/examples/doc-approval" ]; then
  cp -a "$TRAVERSE_REPO/contracts/examples/doc-approval/." "$DEST/_traverse/contracts/examples/doc-approval/"
fi

echo "OK: synced Windows doc-approval bundle → $DEST"
