#!/usr/bin/env bash
# Local onboarding verification — run after setup to confirm repo + runtime wiring.
# Not a CI gate. Does not start or stop processes.
#
# Checks 1–5: local (no runtime required)
# Checks 6–10: runtime probes — SKIP (not FAIL) when runtime unreachable
#
# Exit 0 on pass or skip-only. Exit 1 only on FAIL.
set -uo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
SERVER_JSON="${TRAVERSE_SERVER_JSON:-$REPO_ROOT/.traverse/server.json}"
TIMEOUT="${ONBOARDING_TIMEOUT:-30}"
CAPABILITY_ID="${TRAVERSE_CAPABILITY_ID:-traverse-starter.process}"
WORKSPACE_ID="${TRAVERSE_WORKSPACE_ID:-local-default}"
BASE_URL="${VITE_TRAVERSE_BASE_URL:-http://127.0.0.1:8787}"

FAIL=0

pass() { echo "[PASS] $1"; }
skip() { echo "[SKIP] $1"; }
fail() { echo "[FAIL] $1"; echo "       Fix: $2"; FAIL=1; }

cd "$REPO_ROOT"

echo "=== Onboarding check ==="
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

# Discover runtime for checks 6–10
if [ -n "${TRAVERSE_RUNTIME_URL:-}" ]; then
  BASE_URL="$TRAVERSE_RUNTIME_URL"
elif [ -f "$SERVER_JSON" ]; then
  BASE_URL="$(jq -r '.base_url' "$SERVER_JSON")"
  WORKSPACE_ID="$(jq -r '.workspace_default' "$SERVER_JSON")"
fi

RUNTIME_OK=0
if curl -sf --max-time 3 "$BASE_URL/healthz" >/dev/null 2>&1; then
  RUNTIME_OK=1
fi

if [ "$RUNTIME_OK" -eq 0 ]; then
  skip "[6–10] Runtime not reachable at $BASE_URL — start with: cargo run -p traverse-cli -- serve"
  echo ""
  if [ "$FAIL" -eq 1 ]; then
    echo "FAIL: one or more local checks failed."
    exit 1
  fi
  echo "PASS: local checks OK (runtime steps skipped)."
  exit 0
fi

# [6] Runtime reachable
echo "[6] Runtime reachable..."
pass "Runtime at $BASE_URL"

# [7] /healthz
echo "[7] /healthz..."
HEALTH=$(curl -sf --max-time 5 "$BASE_URL/healthz" 2>&1) || {
  fail "/healthz unreachable" "Start runtime: cargo run -p traverse-cli -- serve"
  echo ""; [ "$FAIL" -eq 1 ] && exit 1; exit 0
}
HEALTH_STATUS=$(echo "$HEALTH" | jq -r '.status' 2>/dev/null || echo "unknown")
if [ "$HEALTH_STATUS" = "ok" ]; then
  pass "/healthz status=ok"
else
  fail "/healthz status=$HEALTH_STATUS" "Check runtime logs at $BASE_URL"
fi

# [8] POST execute
echo "[8] POST execute..."
FIXTURE='{"note": "onboarding check"}'
EXEC_RESPONSE=$(curl -sf --max-time 15 \
  -X POST "$BASE_URL/v1/workspaces/$WORKSPACE_ID/execute" \
  -H "Content-Type: application/json" \
  -d "{\"capability_id\": \"$CAPABILITY_ID\", \"input\": $FIXTURE}" \
  2>&1) || {
  fail "execute request failed" "Verify capability $CAPABILITY_ID is registered; run phase2_smoke.sh or register app"
  echo ""; exit 1
}

EXECUTION_ID=$(echo "$EXEC_RESPONSE" | jq -r '.execution_id // empty' 2>/dev/null || echo "")
EXEC_STATUS=$(echo "$EXEC_RESPONSE" | jq -r '.status' 2>/dev/null || echo "unknown")
RESULT=""

if [ -n "$EXECUTION_ID" ]; then
  pass "execute accepted — execution_id=$EXECUTION_ID"
elif [ "$EXEC_STATUS" = "succeeded" ]; then
  RESULT="$EXEC_RESPONSE"
  pass "execute returned synchronous succeeded"
else
  fail "execute missing execution_id" "Check capability_id=$CAPABILITY_ID and runtime logs"
  echo ""; exit 1
fi

# [9] Poll
if [ -z "$RESULT" ]; then
  echo "[9] Poll for completion..."
  ELAPSED=0
  while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    POLL=$(curl -sf --max-time 5 \
      "$BASE_URL/v1/workspaces/$WORKSPACE_ID/executions/$EXECUTION_ID" 2>&1) || {
      sleep 2; ELAPSED=$((ELAPSED + 2)); continue
    }
    POLL_STATUS=$(echo "$POLL" | jq -r '.status' 2>/dev/null || echo "unknown")
    case "$POLL_STATUS" in
      succeeded) RESULT="$POLL"; break ;;
      failed|error)
        fail "execution failed" "Inspect: curl $BASE_URL/v1/workspaces/$WORKSPACE_ID/executions/$EXECUTION_ID"
        echo ""; exit 1
        ;;
      *) sleep 2; ELAPSED=$((ELAPSED + 2)) ;;
    esac
  done
  if [ -z "$RESULT" ]; then
    fail "execution timed out after ${TIMEOUT}s" "Check runtime execution logs"
    echo ""; exit 1
  fi
  pass "execution succeeded"
else
  echo "[9] Poll..."
  skip "synchronous execute — no poll needed"
fi

# [10] Output fields
echo "[10] Output fields..."
ASSERT_FAIL=0
for field in title tags noteType suggestedNextAction status; do
  value=$(echo "$RESULT" | jq -r ".output.$field // empty" 2>/dev/null || echo "")
  if [ -n "$value" ] && [ "$value" != "null" ]; then
    pass "output.$field present"
  else
    fail "output.$field missing" "Runtime must provide all five fields; check traverse-starter capability"
    ASSERT_FAIL=1
  fi
done

echo ""
if [ "$FAIL" -eq 1 ] || [ "$ASSERT_FAIL" -eq 1 ]; then
  echo "FAIL: onboarding check failed."
  exit 1
fi
echo "PASS: onboarding check complete."
