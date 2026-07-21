#!/usr/bin/env bash
# Sync meeting-notes application bundle into web-react/public for FetchBundleLoader.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
sync_bundle_destination \
  --dest "$REPO_ROOT/apps/meeting-notes/web-react/public/bundles/meeting-notes" \
  --app meeting-notes \
  --components process \
  --manifest-layout root \
  --runtime none \
  --traverse-assets required \
  --label "web meeting-notes"
