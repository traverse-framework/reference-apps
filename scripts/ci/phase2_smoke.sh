#!/usr/bin/env bash
# Phase 2 end-to-end smoke test.
# Proves: app validate → app register → HTTP execute returns runtime output.
#
# Requires:
#   TRAVERSE_REPO — Traverse v0.6.0+ checkout with traverse-starter example (minimum v0.5.0)
#   Runtime at 127.0.0.1:8787 (via .traverse/server.json or TRAVERSE_RUNTIME_URL)
#
# Steps 1–2 (validate) run when TRAVERSE_REPO is set.
# Steps 3–4 (register + execute) run when runtime is reachable.
#
# Exit 0 on pass or skip. Exit 1 on failure.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
MANIFEST="$REPO_ROOT/manifests/traverse-starter/app.manifest.json"
SERVER_JSON="${TRAVERSE_SERVER_JSON:-.traverse/server.json}"
WORKSPACE_ID="${TRAVERSE_WORKSPACE_ID:-local-default}"
CAPABILITY_ID="${TRAVERSE_CAPABILITY_ID:-traverse-starter.pipeline}"

echo "=== Phase 2 smoke test ==="

# ── 1. Link Traverse assets ────────────────────────────────────────────────

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "SKIP: TRAVERSE_REPO not set — Phase 2 smoke skipped."
  exit 0
fi

bash "$REPO_ROOT/scripts/ci/phase2_link_traverse.sh"
echo ""

# ── 2. Validate manifest ───────────────────────────────────────────────────

echo "Step 1: app validate..."
VALIDATE=$(cargo run -p traverse-cli --manifest-path "$TRAVERSE_REPO/Cargo.toml" -- \
  app validate --manifest "$MANIFEST" --json 2>&1) || {
  echo "FAIL: traverse-cli app validate command failed"
  echo "$VALIDATE"
  exit 1
}

VALIDATE_STATUS=$(echo "$VALIDATE" | jq -r '.status' 2>/dev/null || echo "unknown")
if [ "$VALIDATE_STATUS" != "validated" ]; then
  echo "FAIL: app validate status is '$VALIDATE_STATUS' (expected 'validated')"
  echo "$VALIDATE" | jq . 2>/dev/null || echo "$VALIDATE"
  exit 1
fi
echo "OK: manifest validated"
echo ""

# ── 3. Discover runtime ────────────────────────────────────────────────────

if [ -n "${TRAVERSE_RUNTIME_URL:-}" ]; then
  BASE_URL="$TRAVERSE_RUNTIME_URL"
elif [ -f "$SERVER_JSON" ]; then
  BASE_URL="$(jq -r '.base_url' "$SERVER_JSON")"
  WORKSPACE_ID="$(jq -r '.workspace_default' "$SERVER_JSON")"
else
  echo "SKIP: no runtime configured — validate passed, register/execute skipped."
  echo "      Start runtime: cd \$TRAVERSE_REPO && cargo run -p traverse-cli -- serve"
  exit 0
fi

echo "Runtime URL: $BASE_URL"
echo "Workspace: $WORKSPACE_ID"
echo ""

# ── 4. Register app ────────────────────────────────────────────────────────

echo "Step 2: app register..."
REGISTER=$(cargo run -p traverse-cli --manifest-path "$TRAVERSE_REPO/Cargo.toml" -- \
  app register --manifest "$MANIFEST" --workspace "$WORKSPACE_ID" --json 2>&1) || {
  echo "FAIL: traverse-cli app register command failed"
  echo "$REGISTER"
  exit 1
}

REGISTER_STATUS=$(echo "$REGISTER" | jq -r '.status // .registration_status // empty' 2>/dev/null || echo "")
echo "OK: app register completed${REGISTER_STATUS:+ — status=$REGISTER_STATUS}"
echo ""

# ── 5. Execute via HTTP (reuse Phase 1 assertions) ─────────────────────────

echo "Step 3: HTTP execute after registration..."
FIXTURE_INPUT='{"note": "Meeting with design team about onboarding flow improvements"}'

EXEC_RESPONSE=$(curl -sf --max-time 15 \
  -X POST "$BASE_URL/v1/workspaces/$WORKSPACE_ID/execute" \
  -H "Content-Type: application/json" \
  -d "{\"capability_id\": \"$CAPABILITY_ID\", \"input\": $FIXTURE_INPUT}" \
  2>&1) || {
  echo "FAIL: execute request failed"
  echo "$EXEC_RESPONSE"
  exit 1
}

EXECUTION_ID=$(echo "$EXEC_RESPONSE" | jq -r '.execution_id // empty' 2>/dev/null || echo "")
EXEC_STATUS=$(echo "$EXEC_RESPONSE" | jq -r '.status' 2>/dev/null || echo "unknown")

if [ -n "$EXECUTION_ID" ]; then
  echo "OK: execution accepted — execution_id=$EXECUTION_ID"
  TIMEOUT="${SMOKE_TIMEOUT:-30}"
  ELAPSED=0
  RESULT=""
  while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    POLL=$(curl -sf --max-time 5 \
      "$BASE_URL/v1/workspaces/$WORKSPACE_ID/executions/$EXECUTION_ID" 2>&1) || {
      sleep 2; ELAPSED=$((ELAPSED + 2)); continue
    }
    EXEC_STATUS=$(echo "$POLL" | jq -r '.status' 2>/dev/null || echo "unknown")
    case "$EXEC_STATUS" in
      succeeded) RESULT="$POLL"; break ;;
      failed|error)
        echo "FAIL: execution failed"
        echo "$POLL"
        exit 1
        ;;
      *) sleep 2; ELAPSED=$((ELAPSED + 2)) ;;
    esac
  done
  [ -z "$RESULT" ] && { echo "FAIL: execution timed out"; exit 1; }
else
  [ "$EXEC_STATUS" = "succeeded" ] || { echo "FAIL: unexpected execute response"; echo "$EXEC_RESPONSE"; exit 1; }
  RESULT="$EXEC_RESPONSE"
fi

echo ""
echo "Step 4: asserting runtime-provided output fields..."
ASSERT_FAIL=0
for field in validate.valid process.title process.tags process.noteType process.suggestedNextAction process.status summarize.summary summarize.wordCount; do
  value=$(echo "$RESULT" | jq -r ".output.$field // empty" 2>/dev/null || echo "")
  if [ -n "$value" ] && [ "$value" != "null" ]; then
    echo "OK:   output.$field present"
  else
    echo "FAIL: output.$field missing or empty"
    ASSERT_FAIL=1
  fi
done

echo ""
if [ "$ASSERT_FAIL" -eq 1 ]; then
  echo "FAIL: required output fields missing"
  exit 1
fi

echo "PASS: Phase 2 smoke test complete."
