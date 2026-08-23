#!/usr/bin/env bash
# Sync loop bundle into Swift iOS + macOS Resources.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
for DEST in \
  "$REPO_ROOT/apps/loop/ios-swift/Loop/Resources/bundles/loop" \
  "$REPO_ROOT/apps/loop/macos-swift/LoopMac/Resources/bundles/loop"
do
  sync_bundle_destination \
    --dest "$DEST" \
    --app loop \
    --components process,extract,normalize,authorize \
    --manifest-layout root \
    --runtime required \
    --traverse-assets none \
    --label "Swift loop"
done
