#!/usr/bin/env bash
# Sync traverse-starter application bundle into WinUI Assets.
# Shared rules: scripts/ci/sync_bundle_core.sh + docs/runtime-bundle-sync.md
set -euo pipefail
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
sync_bundle_init
sync_bundle_destination \
  --dest "$REPO_ROOT/apps/traverse-starter/windows-winui/TraverseStarter/Assets/bundles/traverse-starter" \
  --app traverse-starter \
  --components validate,process,summarize \
  --manifest-layout root \
  --runtime required \
  --traverse-assets optional \
  --label "WinUI starter"
