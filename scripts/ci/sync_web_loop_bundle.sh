#!/usr/bin/env bash
# Sync loop application bundle into web-react/public for FetchBundleLoader.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
sync_bundle_destination \
  --dest "$REPO_ROOT/apps/loop/web-react/public/bundles/loop" \
  --app loop \
  --components process,extract,normalize,authorize \
  --manifest-layout root \
  --runtime none \
  --traverse-assets optional \
  --label "web loop"
