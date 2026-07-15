#!/usr/bin/env bash
# Sync traverse-starter application bundle into web-react/public for FetchBundleLoader.
# Requires TRAVERSE_REPO (or sibling ../Traverse) with example WASM + workflows.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
DEST="$REPO_ROOT/apps/traverse-starter/web-react/public/bundles/traverse-starter"
MANIFEST_SRC="$REPO_ROOT/manifests/traverse-starter"

if [ ! -d "$TRAVERSE_REPO/examples/traverse-starter" ]; then
  echo "FAIL: TRAVERSE_REPO examples missing: $TRAVERSE_REPO"
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST/components/validate" "$DEST/components/process" "$DEST/components/summarize"
mkdir -p "$DEST/_traverse/examples/traverse-starter"
mkdir -p "$DEST/_traverse/workflows/examples/traverse-starter"
mkdir -p "$DEST/_traverse/contracts/examples/traverse-starter"

cp "$MANIFEST_SRC/app.manifest.json" "$DEST/"
cp "$MANIFEST_SRC/components/validate/component.manifest.json" "$DEST/components/validate/"
cp "$MANIFEST_SRC/components/process/component.manifest.json" "$DEST/components/process/"
cp "$MANIFEST_SRC/components/summarize/component.manifest.json" "$DEST/components/summarize/"

rsync -a "$TRAVERSE_REPO/examples/traverse-starter/" "$DEST/_traverse/examples/traverse-starter/"
rsync -a "$TRAVERSE_REPO/workflows/examples/traverse-starter/" "$DEST/_traverse/workflows/examples/traverse-starter/"
rsync -a "$TRAVERSE_REPO/contracts/examples/traverse-starter/" "$DEST/_traverse/contracts/examples/traverse-starter/"

echo "OK: synced bundle → $DEST"
