#!/usr/bin/env bash
# Sync digest-pinned runtime.wasm into Android assets for traverse-starter.
# Requires TRAVERSE_REPO (or sibling ../Traverse).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
DEST="$REPO_ROOT/apps/traverse-starter/android-compose/app/src/main/assets/bundles/traverse-starter"

if [ ! -f "$TRAVERSE_REPO/runtime/runtime.wasm" ]; then
  echo "FAIL: missing $TRAVERSE_REPO/runtime/runtime.wasm"
  exit 1
fi
if [ ! -f "$TRAVERSE_REPO/runtime/runtime-release.json" ]; then
  echo "FAIL: missing $TRAVERSE_REPO/runtime/runtime-release.json"
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST/runtime"
cp "$TRAVERSE_REPO/runtime/runtime.wasm" "$DEST/runtime/"
cp "$TRAVERSE_REPO/runtime/runtime-release.json" "$DEST/runtime/"

# App manifests (for future bridge orchestration of components)
if [ -d "$REPO_ROOT/manifests/traverse-starter" ]; then
  mkdir -p "$DEST/manifests"
  cp -R "$REPO_ROOT/manifests/traverse-starter/." "$DEST/manifests/"
fi

echo "OK: synced Android starter bundle → $DEST"
