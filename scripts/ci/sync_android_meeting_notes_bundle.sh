#!/usr/bin/env bash
# Sync digest-pinned runtime.wasm into Android assets for meeting-notes.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
sync_bundle_destination \
  --dest "$REPO_ROOT/apps/meeting-notes/android-compose/app/src/main/assets/bundles/meeting-notes" \
  --app meeting-notes \
  --manifest-layout subdir \
  --runtime required \
  --traverse-assets none \
  --label "Android meeting-notes"
