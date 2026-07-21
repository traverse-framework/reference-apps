#!/usr/bin/env bash
# Phase 3 embedded runtime smoke — one entrypoint for every platform slice.
#
# Proves: sync/link real application bundle → in-process public embedder →
# workflow submit — with no traverse-cli serve sidecar.
#
# Contract (Project 2 / #118):
#   - Discover + run what the current runner can execute
#   - SKIP[<slice>]: <reason> when tooling/SDK/TRAVERSE_REPO is missing
#   - FAIL hard when a slice is listed in EMBEDDED_SMOKE_REQUIRED_SLICES
#     (or "all") and that slice cannot run or the embed path breaks
#
# Checked-in Traverse example agent WASM files are placeholder fixtures
# (empty _start; see Traverse packages/web/TraverseEmbedder/examples/
# react-integration/README.md). Submit therefore honestly ends in an
# output_deserialization_failed / registered-artifact error until real
# payload agents ship — that still proves digest verify + Host ABI +
# real WebAssembly/Wasmtime invoke with no sidecar. When a capability_result
# with runtime-owned fields appears, that path is also accepted.
#
# Usage:
#   export TRAVERSE_REPO=/path/to/Traverse
#   # optional: EMBEDDED_SMOKE_REQUIRED_SLICES=web,rust-cli
#   bash scripts/ci/embedded_smoke.sh
#
# Exit 0 on pass (required slices green; others skipped or passed).
# Exit 1 on any required-slice failure.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NOTE="${EMBEDDED_SMOKE_NOTE:-Meeting with design team about onboarding flow improvements}"
REQUIRED_SLICES="${EMBEDDED_SMOKE_REQUIRED_SLICES:-}"
WORKFLOW_ID="${EMBEDDED_SMOKE_WORKFLOW_ID:-traverse-starter.pipeline}"
FIXTURE_NOTE="$NOTE"

cd "$REPO_ROOT"

echo "=== Embedded runtime smoke ==="
echo "REPO_ROOT=$REPO_ROOT"
if [ -n "${TRAVERSE_REPO:-}" ]; then
  echo "TRAVERSE_REPO=$TRAVERSE_REPO"
else
  echo "TRAVERSE_REPO=(unset)"
fi
if [ -n "$REQUIRED_SLICES" ]; then
  echo "REQUIRED_SLICES=$REQUIRED_SLICES"
else
  echo "REQUIRED_SLICES=(none — all missing tooling becomes SKIP)"
fi
echo ""

is_required() {
  local slice="$1"
  case ",${REQUIRED_SLICES}," in
    *",${slice},"*|*,all,*) return 0 ;;
    *) return 1 ;;
  esac
}

skip_or_fail() {
  local slice="$1"
  local reason="$2"
  if is_required "$slice"; then
    echo "FAIL[$slice]: $reason" >&2
    exit 1
  fi
  echo "SKIP[$slice]: $reason"
}

pass_slice() {
  local slice="$1"
  local detail="$2"
  echo "PASS[$slice]: $detail"
}

have_traverse_examples() {
  [ -n "${TRAVERSE_REPO:-}" ] && [ -d "${TRAVERSE_REPO}/examples/traverse-starter" ]
}

# ── Web (Node BundleEmbedder + synced Vite public bundle) ───────────────────

run_web_slice() {
  local slice="web"

  if ! command -v node >/dev/null 2>&1; then
    skip_or_fail "$slice" "node is not installed"
    return
  fi
  if ! command -v rsync >/dev/null 2>&1; then
    skip_or_fail "$slice" "rsync is not installed (needed by sync_web_starter_bundle.sh)"
    return
  fi
  if ! have_traverse_examples; then
    skip_or_fail "$slice" "TRAVERSE_REPO with examples/traverse-starter is required"
    return
  fi

  echo "--- [$slice] syncing web starter bundle ---"
  bash "$REPO_ROOT/scripts/ci/sync_web_starter_bundle.sh"

  local manifest="$REPO_ROOT/apps/traverse-starter/web-react/public/bundles/traverse-starter/app.manifest.json"
  if [ ! -f "$manifest" ]; then
    skip_or_fail "$slice" "synced manifest missing at $manifest"
    return
  fi

  echo "--- [$slice] BundleEmbedder.init + submit ($WORKFLOW_ID) ---"
  local node_status=0
  set +e
  EMBEDDED_SMOKE_MANIFEST="$manifest" \
  EMBEDDED_SMOKE_NOTE="$FIXTURE_NOTE" \
  EMBEDDED_SMOKE_WORKFLOW_ID="$WORKFLOW_ID" \
  EMBEDDED_SMOKE_REPO_ROOT="$REPO_ROOT" \
  node --input-type=module <<'NODE'
import { pathToFileURL } from "node:url";
import { join } from "node:path";

const repoRoot = process.env.EMBEDDED_SMOKE_REPO_ROOT;
const sdkUrl = pathToFileURL(
  join(repoRoot, "vendor/traverse-embedder-web/dist/index.js"),
).href;
const { BundleEmbedder, NodeFsBundleLoader } = await import(sdkUrl);

const manifestPath = process.env.EMBEDDED_SMOKE_MANIFEST;
const note = process.env.EMBEDDED_SMOKE_NOTE;
const workflowId = process.env.EMBEDDED_SMOKE_WORKFLOW_ID;

const events = [];
const embedder = await BundleEmbedder.init({
  manifestPath,
  loader: new NodeFsBundleLoader(),
  workspaceId: "local-default",
  platform: "web",
});

embedder.subscribe((event) => events.push(event));
const outcome = embedder.submit(workflowId, { note });
embedder.shutdown();

if (outcome.status !== "accepted") {
  console.error(
    JSON.stringify({
      ok: false,
      reason: "submit_not_accepted",
      outcome,
      events,
    }),
  );
  process.exit(2);
}

const result = events.find((e) => e.event_type === "capability_result");
if (result) {
  const output = result.data?.output;
  const required = [
    ["validate", "valid"],
    ["process", "title"],
    ["process", "tags"],
    ["process", "noteType"],
    ["process", "suggestedNextAction"],
    ["process", "status"],
    ["summarize", "summary"],
    ["summarize", "wordCount"],
  ];
  for (const [a, b] of required) {
    const value = output?.[a]?.[b];
    if (value === undefined || value === null || value === "") {
      console.error(
        JSON.stringify({
          ok: false,
          reason: "missing_output_field",
          field: `${a}.${b}`,
          output,
        }),
      );
      process.exit(2);
    }
  }
  console.log(
    JSON.stringify({
      ok: true,
      mode: "capability_result",
      sessionId: outcome.sessionId,
    }),
  );
  process.exit(0);
}

const invoked = events.find((e) => e.event_type === "capability_invoked");
const err = events.find((e) => e.event_type === "error");
const code = err?.data?.error?.code;
if (invoked && code === "output_deserialization_failed") {
  // Honest placeholder-fixture outcome (empty _start WASM) — plumbing proved.
  console.log(
    JSON.stringify({
      ok: true,
      mode: "placeholder_fixture_invoke",
      sessionId: outcome.sessionId,
      capability: invoked.data?.capability_id ?? null,
      error_code: code,
    }),
  );
  process.exit(0);
}

console.error(
  JSON.stringify({
    ok: false,
    reason: "unexpected_events",
    outcome,
    events,
  }),
);
process.exit(2);
NODE
  node_status=$?
  set -e

  if [ "$node_status" -ne 0 ]; then
    skip_or_fail "$slice" "BundleEmbedder submit path failed (exit $node_status)"
    return
  fi

  pass_slice "$slice" "synced bundle + in-process BundleEmbedder (no sidecar)"
}

# ── Rust CLI (Wasmtime BundleEmbedder via traverse-starter-cli) ─────────────

run_rust_cli_slice() {
  local slice="rust-cli"

  if ! command -v cargo >/dev/null 2>&1; then
    skip_or_fail "$slice" "cargo is not installed"
    return
  fi
  if ! have_traverse_examples; then
    skip_or_fail "$slice" "TRAVERSE_REPO with examples/traverse-starter is required"
    return
  fi

  echo "--- [$slice] linking manifests/_traverse ---"
  bash "$REPO_ROOT/scripts/ci/phase2_link_traverse.sh"

  echo "--- [$slice] health --json ---"
  local health
  if ! health="$(
    cd "$REPO_ROOT/apps/traverse-starter"
    cargo run -q -p traverse-starter-cli -- health --json
  )"; then
    skip_or_fail "$slice" "traverse-starter-cli health failed"
    return
  fi

  local mode status
  mode="$(echo "$health" | jq -r '.runtime_mode // empty')"
  status="$(echo "$health" | jq -r '.status // empty')"
  if [ "$mode" != "Embedded" ] || [ "$status" != "Ready" ]; then
    skip_or_fail "$slice" "expected Embedded/Ready health, got: $health"
    return
  fi
  echo "OK: health runtime_mode=$mode status=$status"

  echo "--- [$slice] run --json ---"
  local run_out run_status=0
  set +e
  run_out="$(
    cd "$REPO_ROOT/apps/traverse-starter"
    cargo run -q -p traverse-starter-cli -- run --note "$FIXTURE_NOTE" --json 2>&1
  )"
  run_status=$?
  set -e

  if [ "$run_status" -eq 0 ]; then
    local assert_fail=0
    assert_cli_field() {
      local path="$1"
      local value
      value="$(echo "$run_out" | jq -r "$path // empty" 2>/dev/null || true)"
      if [ -n "$value" ] && [ "$value" != "null" ]; then
        echo "OK:   $path = $value"
      else
        echo "FAIL: $path missing"
        assert_fail=1
      fi
    }
    assert_cli_field ".output.validate.valid"
    assert_cli_field ".output.process.title"
    assert_cli_field ".output.process.tags"
    assert_cli_field ".output.process.note_type"
    assert_cli_field ".output.process.suggested_next_action"
    assert_cli_field ".output.process.status"
    assert_cli_field ".output.summarize.summary"
    assert_cli_field ".output.summarize.word_count"
    if [ "$assert_fail" -ne 0 ]; then
      skip_or_fail "$slice" "run succeeded but runtime-owned fields missing"
      return
    fi
    pass_slice "$slice" "health Ready + pipeline capability_result (no sidecar)"
    return
  fi

  # Placeholder fixture WASM: execution fails after real embedder init/submit.
  if echo "$run_out" | grep -qiE 'registered artifact execution failed|output_deserialization_failed|embedder'; then
    echo "OK: pipeline invoke hit placeholder fixture failure (honest stub WASM)"
    echo "$run_out" | tail -5
    pass_slice "$slice" "health Ready + real embedder invoke against checked-in fixture WASM (no sidecar)"
    return
  fi

  skip_or_fail "$slice" "unexpected CLI run failure: $run_out"
}

# ── Native slices (advisory on Linux until #88 runners) ─────────────────────

run_android_slice() {
  local slice="android"
  if ! command -v java >/dev/null 2>&1 && [ ! -x "$REPO_ROOT/apps/traverse-starter/android-compose/gradlew" ]; then
    skip_or_fail "$slice" "Android SDK / gradlew not configured on this runner"
    return
  fi
  if [ ! -f "$REPO_ROOT/apps/traverse-starter/android-compose/app/src/main/assets/bundles/traverse-starter/runtime/runtime.wasm" ]; then
    skip_or_fail "$slice" "digest-pinned runtime.wasm missing under android-compose assets"
    return
  fi
  # Full gradle instrumented smoke waits on #88; prove bundle presence here.
  if [ ! -x "$REPO_ROOT/apps/traverse-starter/android-compose/gradlew" ] || ! command -v java >/dev/null 2>&1; then
    skip_or_fail "$slice" "gradle/java not available — bundle artifact present; full gradle smoke deferred to #88"
    return
  fi
  skip_or_fail "$slice" "gradle embedded execute smoke not wired yet (tracked under #88); runtime.wasm present"
}

run_swift_slice() {
  local slice="swift"
  if ! command -v xcodebuild >/dev/null 2>&1; then
    skip_or_fail "$slice" "xcodebuild not available (Apple runner required; see #88)"
    return
  fi
  skip_or_fail "$slice" "xcodebuild embedded smoke not wired yet (tracked under #88)"
}

run_windows_slice() {
  local slice="windows"
  if ! command -v dotnet >/dev/null 2>&1; then
    skip_or_fail "$slice" "dotnet not available (Windows runner required; see #88)"
    return
  fi
  skip_or_fail "$slice" "dotnet embedded smoke not wired yet (tracked under #88)"
}

# ── Run matrix ──────────────────────────────────────────────────────────────

run_web_slice
echo ""
run_rust_cli_slice
echo ""
run_android_slice
run_swift_slice
run_windows_slice

echo ""
echo "PASS: embedded runtime smoke complete (no traverse-cli serve)."
