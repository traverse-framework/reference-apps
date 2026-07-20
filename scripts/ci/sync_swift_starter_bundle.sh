#!/usr/bin/env bash
# Sync traverse-starter application bundle into iOS + macOS Swift app resources.
# Requires TRAVERSE_REPO (or sibling ../Traverse) with runtime/runtime.wasm.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
MANIFEST_SRC="$REPO_ROOT/manifests/traverse-starter"

IOS_DEST="$REPO_ROOT/apps/traverse-starter/ios-swift/TraverseStarter/Resources/bundles/traverse-starter"
MACOS_DEST="$REPO_ROOT/apps/traverse-starter/macos-swift/TraverseStarterMac/Resources/bundles/traverse-starter"

if [ ! -f "$TRAVERSE_REPO/runtime/runtime.wasm" ]; then
  echo "FAIL: TRAVERSE_REPO runtime missing: $TRAVERSE_REPO/runtime/runtime.wasm"
  exit 1
fi

sync_bundle() {
  local DEST="$1"
  rm -rf "$DEST"
  mkdir -p "$DEST/runtime"
  mkdir -p "$DEST/components/validate" "$DEST/components/process" "$DEST/components/summarize"
  mkdir -p "$DEST/_traverse/examples/traverse-starter"
  mkdir -p "$DEST/_traverse/workflows/examples/traverse-starter"
  mkdir -p "$DEST/_traverse/contracts/examples/traverse-starter"

  cp "$MANIFEST_SRC/app.manifest.json" "$DEST/"
  cp "$MANIFEST_SRC/components/validate/component.manifest.json" "$DEST/components/validate/"
  cp "$MANIFEST_SRC/components/process/component.manifest.json" "$DEST/components/process/"
  cp "$MANIFEST_SRC/components/summarize/component.manifest.json" "$DEST/components/summarize/"

  cp "$TRAVERSE_REPO/runtime/runtime.wasm" "$DEST/runtime/"
  cp "$TRAVERSE_REPO/runtime/runtime-release.json" "$DEST/runtime/"

  if [ -d "$TRAVERSE_REPO/examples/traverse-starter" ]; then
    cp -a "$TRAVERSE_REPO/examples/traverse-starter/." "$DEST/_traverse/examples/traverse-starter/"
  fi
  if [ -d "$TRAVERSE_REPO/workflows/examples/traverse-starter" ]; then
    cp -a "$TRAVERSE_REPO/workflows/examples/traverse-starter/." "$DEST/_traverse/workflows/examples/traverse-starter/"
  fi
  if [ -d "$TRAVERSE_REPO/contracts/examples/traverse-starter" ]; then
    cp -a "$TRAVERSE_REPO/contracts/examples/traverse-starter/." "$DEST/_traverse/contracts/examples/traverse-starter/"
  fi
  echo "OK: synced → $DEST"
}

sync_bundle "$IOS_DEST"
sync_bundle "$MACOS_DEST"

echo "OK: Swift starter bundles synced."
