#!/usr/bin/env bash
# Phase 1 end-to-end smoke test.
# Proves: workflow start → runtime event receipt → final rendered output.
#
# Requires a local Traverse runtime running (or TRAVERSE_RUNTIME_URL set).
# Set TRAVERSE_REPO to use a local Traverse build instead of the pinned release.
#
# Exit 0 on pass. Exit 1 on failure with diff output.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
RUNTIME_URL="${TRAVERSE_RUNTIME_URL:-http://localhost:3000}"
TIMEOUT="${SMOKE_TIMEOUT:-30}"

echo "=== Phase 1 smoke test ==="
echo "Runtime URL: $RUNTIME_URL"
echo ""

# ── 1. Check runtime is reachable ──────────────────────────────────────────

echo "Step 1: checking runtime availability..."
if ! curl -sf --max-time 5 "$RUNTIME_URL/health" > /dev/null 2>&1; then
  echo "FAIL: Traverse runtime not reachable at $RUNTIME_URL"
  echo ""
  echo "Start the local runtime before running this smoke test:"
  if [ -n "${TRAVERSE_REPO:-}" ]; then
    echo "  cd \$TRAVERSE_REPO && cargo run -p traverse-cli -- serve"
  else
    echo "  npx traverse-cli serve"
  fi
  exit 1
fi
echo "OK: runtime reachable"
echo ""

# ── 2. Start workflow ───────────────────────────────────────────────────────

echo "Step 2: starting workflow with fixture input..."
FIXTURE_INPUT='{"note": "Meeting with design team about onboarding flow"}'

WORKFLOW_RESPONSE=$(curl -sf --max-time 10 \
  -X POST "$RUNTIME_URL/workflow/start" \
  -H "Content-Type: application/json" \
  -d "{\"workflowId\": \"traverse-starter\", \"input\": $FIXTURE_INPUT}" \
  2>&1) || {
  echo "FAIL: workflow start request failed"
  echo "$WORKFLOW_RESPONSE"
  exit 1
}

RUN_ID=$(echo "$WORKFLOW_RESPONSE" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  if (!d.runId) { console.error('No runId in response:', JSON.stringify(d)); process.exit(1); }
  process.stdout.write(d.runId);
" 2>&1) || {
  echo "FAIL: could not extract runId from workflow start response"
  echo "Response: $WORKFLOW_RESPONSE"
  exit 1
}

echo "OK: workflow started — runId: $RUN_ID"
echo ""

# ── 3. Poll for completion ──────────────────────────────────────────────────

echo "Step 3: polling for workflow completion (timeout: ${TIMEOUT}s)..."
ELAPSED=0
STATUS=""
RESULT=""

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  POLL_RESPONSE=$(curl -sf --max-time 5 "$RUNTIME_URL/workflow/$RUN_ID" 2>&1) || {
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    continue
  }

  STATUS=$(echo "$POLL_RESPONSE" | node -e "
    const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
    process.stdout.write(d.status || 'unknown');
  " 2>/dev/null || echo "unknown")

  if [ "$STATUS" = "completed" ]; then
    RESULT="$POLL_RESPONSE"
    break
  elif [ "$STATUS" = "failed" ]; then
    echo "FAIL: workflow failed"
    echo "$POLL_RESPONSE"
    exit 1
  fi

  echo "  status: $STATUS (${ELAPSED}s elapsed)"
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

if [ "$STATUS" != "completed" ]; then
  echo "FAIL: workflow did not complete within ${TIMEOUT}s (last status: $STATUS)"
  exit 1
fi

echo "OK: workflow completed"
echo ""

# ── 4. Assert required output fields ───────────────────────────────────────

echo "Step 4: asserting required runtime-provided output fields..."
ASSERT_FAIL=0

assert_field() {
  local field="$1"
  local value
  value=$(echo "$RESULT" | node -e "
    const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
    const v = d.output && d.output['$field'];
    process.stdout.write(v !== undefined && v !== null && v !== '' ? 'ok' : 'missing');
  " 2>/dev/null || echo "missing")

  if [ "$value" = "ok" ]; then
    echo "OK:   output.$field present"
  else
    echo "FAIL: output.$field missing or empty"
    ASSERT_FAIL=1
  fi
}

assert_field "title"
assert_field "tags"
assert_field "noteType"
assert_field "suggestedNextAction"
assert_field "status"

echo ""
if [ "$ASSERT_FAIL" -eq 1 ]; then
  echo "FAIL: one or more required output fields missing."
  echo "Full result:"
  echo "$RESULT" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(JSON.stringify(d,null,2));"
  exit 1
fi

echo "PASS: Phase 1 smoke test complete."
echo "  runId:  $RUN_ID"
echo "  status: completed"
