#!/usr/bin/env bash
# Sync digest-pinned runtime.wasm into Android assets for traverse-starter.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
sync_bundle_destination \
  --dest "$REPO_ROOT/apps/traverse-starter/android-compose/app/src/main/assets/bundles/traverse-starter" \
  --app traverse-starter \
  --manifest-layout subdir \
  --runtime required \
  --traverse-assets none \
  --label "Android starter"
