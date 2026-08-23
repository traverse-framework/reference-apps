#!/usr/bin/env bash
# Sync digest-pinned runtime.wasm into Android assets for loop.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
sync_bundle_destination \
  --dest "$REPO_ROOT/apps/loop/android-compose/app/src/main/assets/bundles/loop" \
  --app loop \
  --components process,extract,normalize,authorize \
  --manifest-layout subdir \
  --runtime required \
  --traverse-assets none \
  --label "Android loop"
