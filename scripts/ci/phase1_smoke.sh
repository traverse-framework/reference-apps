#!/usr/bin/env bash
# Phase 1 end-to-end smoke test.
# Proves: runtime reachable → execute capability → poll completion → output fields present.
#
# Governed by spec 033-http-json-api (approved v1.1.0).
# Runtime: traverse-cli serve at 127.0.0.1:8787, discovery via .traverse/server.json.
# Minimum Traverse version: v0.3.0 — tested with v0.6.0 (current release).
#
# Set TRAVERSE_RUNTIME_URL to override default discovery.
# Set TRAVERSE_CAPABILITY_ID to override the capability being tested
#   (default: traverse-starter.pipeline, input field: note).
# Exit 0 on pass. Exit 1 on failure.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
SERVER_JSON="${TRAVERSE_SERVER_JSON:-.traverse/server.json}"
TIMEOUT="${SMOKE_TIMEOUT:-30}"
CAPABILITY_ID="${TRAVERSE_CAPABILITY_ID:-traverse-starter.pipeline}"

echo "=== Phase 1 smoke test ==="

# ── 1. Discover runtime ────────────────────────────────────────────────────

if [ -n "${TRAVERSE_RUNTIME_URL:-}" ]; then
  BASE_URL="$TRAVERSE_RUNTIME_URL"
  WORKSPACE_ID="${TRAVERSE_WORKSPACE_ID:-local-default}"
  echo "Runtime URL (override): $BASE_URL"
  echo "Workspace: $WORKSPACE_ID"
elif [ -f "$SERVER_JSON" ]; then
  BASE_URL="$(jq -r '.base_url' "$SERVER_JSON")"
  WORKSPACE_ID="$(jq -r '.workspace_default' "$SERVER_JSON")"
  echo "Runtime URL (discovered): $BASE_URL"
  echo "Workspace: $WORKSPACE_ID"
else
  echo "SKIP: .traverse/server.json not found and TRAVERSE_RUNTIME_URL not set."
  echo "      Set TRAVERSE_RUNTIME_URL or run 'cargo run -p traverse-cli -- serve' first."
  echo "SKIP: Phase 1 smoke skipped — no runtime configured."
  exit 0
fi

echo ""

# ── 2. Health check ────────────────────────────────────────────────────────

echo "Step 1: health check..."
HEALTH=$(curl -sf --max-time 5 "$BASE_URL/healthz" 2>&1) || {
  echo "FAIL: runtime not reachable at $BASE_URL/healthz"
  exit 1
}

STATUS=$(echo "$HEALTH" | jq -r '.status' 2>/dev/null || echo "unknown")
API_VERSION=$(echo "$HEALTH" | jq -r '.api_version' 2>/dev/null || echo "unknown")

if [ "$STATUS" != "ok" ]; then
  echo "FAIL: health status is '$STATUS' (expected 'ok')"
  echo "$HEALTH"
  exit 1
fi

echo "OK: runtime healthy — api_version=$API_VERSION workspace=$WORKSPACE_ID"
echo ""

# ── 3. Execute capability ──────────────────────────────────────────────────

echo "Step 2: executing capability '$CAPABILITY_ID'..."
FIXTURE_INPUT='{"note": "Meeting with design team about onboarding flow improvements"}'

EXEC_RESPONSE=$(curl -sf --max-time 15 \
  -X POST "$BASE_URL/v1/workspaces/$WORKSPACE_ID/execute" \
  -H "Content-Type: application/json" \
  -d "{\"capability_id\": \"$CAPABILITY_ID\", \"input\": $FIXTURE_INPUT}" \
  2>&1) || {
  echo "FAIL: execute request failed at POST /v1/workspaces/$WORKSPACE_ID/execute"
  echo "$EXEC_RESPONSE"
  exit 1
}

EXEC_STATUS=$(echo "$EXEC_RESPONSE" | jq -r '.status' 2>/dev/null || echo "unknown")
EXECUTION_ID=$(echo "$EXEC_RESPONSE" | jq -r '.execution_id // empty' 2>/dev/null || echo "")

if [ -z "$EXECUTION_ID" ] && [ "$EXEC_STATUS" = "succeeded" ]; then
  # Synchronous completion — output is inline
  echo "OK: synchronous execution completed"
  RESULT="$EXEC_RESPONSE"
elif [ -n "$EXECUTION_ID" ]; then
  echo "OK: execution accepted — execution_id=$EXECUTION_ID"
  RESULT=""
else
  echo "FAIL: execute response missing execution_id and status is not succeeded"
  echo "$EXEC_RESPONSE"
  exit 1
fi

echo ""

# ── 4. Poll for completion (if async) ─────────────────────────────────────

if [ -z "$RESULT" ]; then
  echo "Step 3: polling for completion (timeout: ${TIMEOUT}s)..."
  ELAPSED=0

  while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    POLL=$(curl -sf --max-time 5 \
      "$BASE_URL/v1/workspaces/$WORKSPACE_ID/executions/$EXECUTION_ID" \
      2>&1) || { sleep 2; ELAPSED=$((ELAPSED + 2)); continue; }

    EXEC_STATUS=$(echo "$POLL" | jq -r '.status' 2>/dev/null || echo "unknown")

    case "$EXEC_STATUS" in
      succeeded)
        RESULT="$POLL"
        echo "OK: execution succeeded"
        break
        ;;
      failed|error)
        echo "FAIL: execution failed"
        echo "$POLL"
        exit 1
        ;;
      *)
        echo "  status: $EXEC_STATUS (${ELAPSED}s elapsed)"
        sleep 2
        ELAPSED=$((ELAPSED + 2))
        ;;
    esac
  done

  if [ -z "$RESULT" ]; then
    echo "FAIL: execution did not complete within ${TIMEOUT}s (last status: $EXEC_STATUS)"
    exit 1
  fi

  echo ""
fi

# ── 5. Assert output fields ────────────────────────────────────────────────

echo "Step 4: asserting runtime-provided output fields..."
ASSERT_FAIL=0

assert_field() {
  local field="$1"
  local value
  value=$(echo "$RESULT" | jq -r ".output.$field // empty" 2>/dev/null || echo "")
  if [ -n "$value" ] && [ "$value" != "null" ]; then
    echo "OK:   output.$field = $value"
  else
    echo "FAIL: output.$field missing or empty"
    ASSERT_FAIL=1
  fi
}

# Fields are runtime-owned — UI must not compute these
assert_field "validate.valid"
assert_field "process.title"
assert_field "process.tags"
assert_field "process.noteType"
assert_field "process.suggestedNextAction"
assert_field "process.status"
assert_field "summarize.summary"
assert_field "summarize.wordCount"

echo ""
if [ "$ASSERT_FAIL" -eq 1 ]; then
  echo "FAIL: one or more required output fields missing."
  echo "Full result:"
  echo "$RESULT" | jq .
  exit 1
fi

# ── 6. Fetch trace ─────────────────────────────────────────────────────────

if [ -n "$EXECUTION_ID" ]; then
  echo "Step 5: fetching public trace..."
  TRACE=$(curl -sf --max-time 5 \
    "$BASE_URL/v1/workspaces/$WORKSPACE_ID/traces/$EXECUTION_ID" 2>&1) || {
    echo "WARN: trace fetch failed (non-blocking)"
  }
  TRACE_STATUS=$(echo "$TRACE" | jq -r '.status // empty' 2>/dev/null || echo "")
  [ -n "$TRACE_STATUS" ] && echo "OK:   trace status=$TRACE_STATUS" || echo "WARN: trace not available"
  echo ""
fi

echo "PASS: Phase 1 smoke test complete."
[ -n "$EXECUTION_ID" ] && echo "  execution_id: $EXECUTION_ID"
echo "  status: succeeded"
