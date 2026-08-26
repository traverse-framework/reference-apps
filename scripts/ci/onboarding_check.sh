#!/usr/bin/env bash
# Local onboarding verification — repo wiring + embedded kit bar.
# Not a CI gate. Does not start or stop processes.
#
# Checks 1–5: local npm (no Traverse checkout required)
# Checks 6–8 and 10: always (manifest / registry_ref / runbook)
# Check 9: SKIP (not FAIL) when TRAVERSE_REPO unset
#
# Exit 0 on pass or skip-only. Exit 1 only on FAIL.
# Do NOT treat traverse-cli serve / 127.0.0.1:8787 as the production path.
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
TIMEOUT="${ONBOARDING_TIMEOUT:-30}"
MANIFEST="$REPO_ROOT/manifests/traverse-starter/app.manifest.json"
PROCESS_COMP="$REPO_ROOT/manifests/traverse-starter/components/process/component.manifest.json"

FAIL=0

pass() { echo "[PASS] $1"; }
skip() { echo "[SKIP] $1"; }
fail() { echo "[FAIL] $1"; echo "       Fix: $2"; FAIL=1; }

cd "$REPO_ROOT"

echo "=== Onboarding check (embedded kit) ==="
echo ""

# [1] Node version
echo "[1] Node version (.nvmrc)..."
REQUIRED_NODE="$(tr -d 'v' < .nvmrc 2>/dev/null || echo 24)"
ACTUAL_NODE="$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)"
if [ "$ACTUAL_NODE" -ge "$REQUIRED_NODE" ] 2>/dev/null; then
  pass "Node ${ACTUAL_NODE}+ (required ${REQUIRED_NODE}+)"
else
  fail "Node ${ACTUAL_NODE} < required ${REQUIRED_NODE}" "Install Node ${REQUIRED_NODE}+ (see .nvmrc)"
fi

# [2] npm install
echo "[2] npm install..."
if npm install >/dev/null 2>&1; then
  pass "npm install"
else
  fail "npm install failed" "Run: npm install"
fi

# [3] typecheck
echo "[3] typecheck..."
if npm run typecheck >/dev/null 2>&1; then
  pass "npm run typecheck"
else
  fail "typecheck failed" "Run: npm run typecheck"
fi

# [4] lint
echo "[4] lint..."
if npm run lint >/dev/null 2>&1; then
  pass "npm run lint"
else
  fail "lint failed" "Run: npm run lint"
fi

# [5] tests
echo "[5] tests..."
if npm run test >/dev/null 2>&1; then
  pass "npm run test"
else
  fail "tests failed" "Run: npm run test"
fi

# [6–10] Embedded kit — no sidecar
echo ""
echo "Embedded kit probes (docs: docs/kit-runner-persona.md)"
echo "[6] traverse-starter app.manifest.json kit fields..."
if [ ! -f "$MANIFEST" ]; then
  fail "missing $MANIFEST" "Restore manifests/traverse-starter/app.manifest.json"
else
  sm=$(jq -e '.state_machine' "$MANIFEST" >/dev/null 2>&1; echo $?)
  wf=$(jq -e '.workflows | length > 0' "$MANIFEST" >/dev/null 2>&1; echo $?)
  cs=$(jq -e '.config_schema' "$MANIFEST" >/dev/null 2>&1; echo $?)
  dc=$(jq -e '.default_config' "$MANIFEST" >/dev/null 2>&1; echo $?)
  if [ "$sm" -eq 0 ] && [ "$wf" -eq 0 ] && [ "$cs" -eq 0 ] && [ "$dc" -eq 0 ]; then
    pass "state_machine + workflows + config_schema + default_config"
  else
    fail "app.manifest.json missing kit fields" "Need state_machine, workflows[], config_schema, default_config"
  fi
fi

echo "[7] process component registry_ref..."
if [ ! -f "$PROCESS_COMP" ]; then
  fail "missing process component manifest" "Restore manifests/traverse-starter/components/process/component.manifest.json"
elif jq -e '.registry_ref.namespace and .registry_ref.id' "$PROCESS_COMP" >/dev/null 2>&1; then
  pass "process component uses registry_ref"
else
  fail "process component has no registry_ref" "Kit caps must be registry_ref (see docs/production-packaging.md)"
fi

echo "[8] persona runbook + sync wrapper..."
if [ -f "$REPO_ROOT/docs/kit-runner-persona.md" ] && [ -f "$REPO_ROOT/scripts/ci/sync_web_starter_bundle.sh" ]; then
  pass "kit-runner-persona.md + sync_web_starter_bundle.sh"
else
  fail "missing runbook or web sync wrapper" "Need docs/kit-runner-persona.md and scripts/ci/sync_web_starter_bundle.sh"
fi

echo "[9] TRAVERSE_REPO (optional live embed)..."
if [ -z "${TRAVERSE_REPO:-}" ]; then
  skip "TRAVERSE_REPO unset — set it and run bash scripts/ci/sync_web_starter_bundle.sh then embedded_smoke (linux)"
elif [ ! -d "$TRAVERSE_REPO" ]; then
  fail "TRAVERSE_REPO is not a directory" "export TRAVERSE_REPO=/absolute/path/to/Traverse"
else
  pass "TRAVERSE_REPO=$TRAVERSE_REPO"
fi

echo "[10] production path reminder..."
if grep -Fq 'Do **not** start `traverse-cli serve`' "$REPO_ROOT/docs/kit-runner-persona.md"; then
  pass "persona runbook forbids traverse-cli serve for OS shells"
else
  fail "persona runbook missing serve prohibition" "docs/kit-runner-persona.md must tell personas not to start traverse-cli serve"
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo "FAIL: onboarding check failed."
  exit 1
fi
echo "PASS: onboarding check complete."
echo "Next: docs/kit-runner-persona.md — do not start traverse-cli serve for OS shells."
