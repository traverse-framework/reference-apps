#!/usr/bin/env bash
# Sync meeting-notes bundle into Swift iOS + macOS Resources.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
for DEST in \
  "$REPO_ROOT/apps/meeting-notes/ios-swift/MeetingNotes/Resources/bundles/meeting-notes" \
  "$REPO_ROOT/apps/meeting-notes/macos-swift/MeetingNotesMac/Resources/bundles/meeting-notes"
do
  sync_bundle_destination \
    --dest "$DEST" \
    --app meeting-notes \
    --components process \
    --manifest-layout root \
    --runtime required \
    --traverse-assets none \
    --label "Swift meeting-notes"
done
