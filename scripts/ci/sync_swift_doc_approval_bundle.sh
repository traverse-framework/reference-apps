#!/usr/bin/env bash
# Sync doc-approval bundle into Swift iOS + macOS Resources.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
for DEST in \
  "$REPO_ROOT/apps/doc-approval/ios-swift/DocApproval/Resources/bundles/doc-approval" \
  "$REPO_ROOT/apps/doc-approval/macos-swift/DocApprovalMac/Resources/bundles/doc-approval"
do
  sync_bundle_destination \
    --dest "$DEST" \
    --app doc-approval \
    --components analyze,recommend \
    --manifest-layout root \
    --runtime required \
    --traverse-assets none \
    --label "Swift doc-approval"
done
