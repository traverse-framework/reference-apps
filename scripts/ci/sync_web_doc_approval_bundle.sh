#!/usr/bin/env bash
# Sync doc-approval application bundle into web-react/public for FetchBundleLoader.
# Requires TRAVERSE_REPO (or sibling ../Traverse) with example WASM + workflows.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
DEST="$REPO_ROOT/apps/doc-approval/web-react/public/bundles/doc-approval"
MANIFEST_SRC="$REPO_ROOT/manifests/doc-approval"

if [ ! -d "$TRAVERSE_REPO/examples/doc-approval" ]; then
  echo "FAIL: TRAVERSE_REPO examples missing: $TRAVERSE_REPO"
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST/components/analyze" "$DEST/components/recommend"
mkdir -p "$DEST/_traverse/examples/doc-approval"
mkdir -p "$DEST/_traverse/examples/applications/doc-approval"
mkdir -p "$DEST/_traverse/workflows/examples/doc-approval"
mkdir -p "$DEST/_traverse/contracts/examples/doc-approval"

cp "$MANIFEST_SRC/app.manifest.json" "$DEST/"
cp "$MANIFEST_SRC/components/analyze/component.manifest.json" "$DEST/components/analyze/"
cp "$MANIFEST_SRC/components/recommend/component.manifest.json" "$DEST/components/recommend/"

rsync -a "$TRAVERSE_REPO/examples/doc-approval/" "$DEST/_traverse/examples/doc-approval/"
rsync -a "$TRAVERSE_REPO/workflows/examples/doc-approval/" "$DEST/_traverse/workflows/examples/doc-approval/"
rsync -a "$TRAVERSE_REPO/contracts/examples/doc-approval/" "$DEST/_traverse/contracts/examples/doc-approval/"

echo "OK: synced bundle → $DEST"
