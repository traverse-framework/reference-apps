#!/usr/bin/env bash
# Prove new-app-author remap + Web host constants (no sidecar, no business fields).
# Does not start processes. Does not require TRAVERSE_REPO.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
FIXTURE="$REPO_ROOT/scripts/ci/fixtures/app-new-scaffold/youaskm3"
HOST_SRC="$REPO_ROOT/apps/traverse-starter/web-react/src/host/embeddedHost.ts"
README_SRC="$REPO_ROOT/apps/traverse-starter/web-react/README.md"
FAIL=0

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; FAIL=1; }

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required"
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== New-app author check ==="

echo "[1] remap CLI scaffold (no seed)..."
bash "$REPO_ROOT/scripts/ci/remap_app_new_to_kit.sh" \
  --from "$FIXTURE" \
  --out "$TMP/empty/youaskm3"
if [ -f "$TMP/empty/youaskm3/app.manifest.json" ] && [ ! -f "$TMP/empty/youaskm3/manifest.json" ]; then
  pass "filename is app.manifest.json"
else
  fail "expected app.manifest.json only"
fi
empty_wf="$(jq '.workflows | length' "$TMP/empty/youaskm3/app.manifest.json")"
if [ "$empty_wf" = "0" ]; then
  pass "empty scaffold still has no workflows (not a product app)"
else
  fail "empty remap should not invent workflows"
fi
if jq -e '.state_machine' "$TMP/empty/youaskm3/app.manifest.json" >/dev/null 2>&1; then
  fail "empty scaffold should not invent a state_machine"
else
  pass "empty scaffold has no state_machine"
fi

echo "[2] remap + seed traverse-starter (kit bar)..."
APP_ID="persona-demo"
bash "$REPO_ROOT/scripts/ci/remap_app_new_to_kit.sh" \
  --from "$FIXTURE" \
  --out "$TMP/kit/$APP_ID" \
  --app-id "$APP_ID" \
  --seed-from traverse-starter
MANIFEST="$TMP/kit/$APP_ID/app.manifest.json"
PROCESS="$TMP/kit/$APP_ID/components/process/component.manifest.json"
got_id="$(jq -r '.app_id' "$MANIFEST")"
got_wf="$(jq -r '.workflows[0].workflow_id' "$MANIFEST")"
if [ "$got_id" = "$APP_ID" ]; then
  pass "app_id=$APP_ID"
else
  fail "app_id is $got_id"
fi
if [ "$got_wf" = "traverse-starter.pipeline" ]; then
  pass "workflow id remains traverse-starter.pipeline (reuse published WASM)"
else
  fail "workflow_id unexpectedly $got_wf"
fi
if jq -e '.state_machine' "$MANIFEST" >/dev/null 2>&1 \
  && jq -e '.config_schema' "$MANIFEST" >/dev/null 2>&1 \
  && jq -e '.default_config' "$MANIFEST" >/dev/null 2>&1 \
  && jq -e '.workflows | length > 0' "$MANIFEST" >/dev/null 2>&1; then
  pass "state_machine + config + workflows"
else
  fail "seeded manifest missing kit fields"
fi
if jq -e '.registry_ref.namespace and .registry_ref.id' "$PROCESS" >/dev/null 2>&1; then
  pass "process component registry_ref"
else
  fail "seeded process component missing registry_ref"
fi
if [ -e "$TMP/kit/$APP_ID/_traverse" ]; then
  fail "seed copied _traverse symlink (must stay out of author output)"
else
  pass "no _traverse symlink in remapped tree"
fi
if [ -f "$TMP/kit/$APP_ID/workspace.config.json" ]; then
  fail "seeded tree kept CLI workspace.config.json"
else
  pass "CLI workspace.config.json not carried over after seed"
fi
ws="$(jq -r '.workspace_defaults.workspace_id' "$MANIFEST")"
if [ "$ws" = "local-default" ]; then
  pass "workspace_defaults.workspace_id=local-default"
else
  fail "workspace_id is $ws (expected local-default from starter seed)"
fi

echo "[3] Web OS twin (copy starter host constants)..."
if [ ! -f "$HOST_SRC" ] || [ ! -f "$README_SRC" ]; then
  fail "missing traverse-starter web-react host/README"
else
  mkdir -p "$TMP/web/src/host"
  # Keep workflow id; only rewrite app identity + bundle path.
  sed \
    -e "s|export const DEFAULT_APP_ID = 'traverse-starter'|export const DEFAULT_APP_ID = '${APP_ID}'|" \
    -e "s|export const DEFAULT_MANIFEST_PATH = '/bundles/traverse-starter/app.manifest.json'|export const DEFAULT_MANIFEST_PATH = '/bundles/${APP_ID}/app.manifest.json'|" \
    "$HOST_SRC" >"$TMP/web/src/host/embeddedHost.ts"
  if grep -q "DEFAULT_APP_ID = '${APP_ID}'" "$TMP/web/src/host/embeddedHost.ts" \
    && grep -q "/bundles/${APP_ID}/app.manifest.json" "$TMP/web/src/host/embeddedHost.ts" \
    && grep -q "DEFAULT_WORKFLOW_ID = 'traverse-starter.pipeline'" "$TMP/web/src/host/embeddedHost.ts" \
    && grep -q "BundleEmbedder" "$TMP/web/src/host/embeddedHost.ts" \
    && grep -q "traverse-embedder-web" "$TMP/web/src/host/embeddedHost.ts"; then
    pass "Web host constants rewrite (embedded BundleEmbedder)"
  else
    fail "Web host rewrite did not keep public embedder + starter workflow"
  fi
  if grep -Eq '127\.0\.0\.1:8787|traverse-cli -- serve' "$TMP/web/src/host/embeddedHost.ts"; then
    fail "rewritten host references sidecar"
  else
    pass "rewritten host has no sidecar URL"
  fi
  if grep -qi 'Runtime mode: embedded' "$README_SRC"; then
    pass "starter Web README documents Runtime mode: Embedded (copy this)"
  else
    fail "starter Web README missing Runtime mode: Embedded"
  fi
fi

echo "[4] remap helper does not treat sidecar as production..."
if grep -Eq 'cargo run -p traverse-cli -- serve|VITE_TRAVERSE_BASE_URL=http://127.0.0.1:8787' \
  "$REPO_ROOT/scripts/ci/remap_app_new_to_kit.sh"; then
  fail "remap helper encodes sidecar as production"
else
  pass "no sidecar serve / 8787 production probe in remap helper"
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo "FAIL: new-app author check failed."
  exit 1
fi
echo "PASS: new-app author check complete."
