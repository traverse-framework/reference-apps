#!/usr/bin/env bash
# Sync traverse-starter bundle into Swift iOS + macOS Resources.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
for DEST in \
  "$REPO_ROOT/apps/traverse-starter/ios-swift/TraverseStarter/Resources/bundles/traverse-starter" \
  "$REPO_ROOT/apps/traverse-starter/macos-swift/TraverseStarterMac/Resources/bundles/traverse-starter"
do
  sync_bundle_destination \
    --dest "$DEST" \
    --app traverse-starter \
    --components validate,process,summarize \
    --manifest-layout root \
    --runtime required \
    --traverse-assets none \
    --label "Swift starter"
done
