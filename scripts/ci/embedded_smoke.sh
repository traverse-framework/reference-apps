#!/usr/bin/env bash
# Embedded runtime smoke — Phase 3 production path (no traverse-cli serve).
#
# One entrypoint, all primary platforms. Skip-with-reason when an SDK is missing;
# hard-fail when the runner is expected to run that slice.
#
# Env:
#   TRAVERSE_REPO                 Traverse checkout (default: $REPO_ROOT/../Traverse)
#   EMBEDDED_SMOKE_EXPECT         linux | all | auto  (default: auto; CI sets linux)
#                                 linux → web + cli required
#                                 all   → every slice required (native SDKs must exist)
#                                 auto  → require a slice only when its tools are present
#   EMBEDDED_SMOKE_SKIP=<csv>     force-skip slices (web,cli,gtk,android,swift,windows)
#
# Web + CLI always require runtime-owned pipeline output (validate/process/summarize)
# via digest-pinned Traverse-published agents under
# scripts/ci/fixtures/traverse-starter-smoke-agents/ (see digests.json provenance).
#
# Exit 0 on pass (skips allowed). Exit 1 on any required-slice failure.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
EXPECT="${EMBEDDED_SMOKE_EXPECT:-auto}"
SKIP_CSV="${EMBEDDED_SMOKE_SKIP:-}"
UNAME="$(uname -s)"

PASS=0
FAIL=0
SKIP=0

log() { echo "$*"; }
ok() { log "OK: $*"; PASS=$((PASS + 1)); }
fail() { log "FAIL: $*"; FAIL=$((FAIL + 1)); }
skip() { log "SKIP: $*"; SKIP=$((SKIP + 1)); }

forced_skip() {
  local slice="$1"
  [[ ",${SKIP_CSV}," == *",${slice},"* ]]
}

slice_expected() {
  local slice="$1"
  case "$EXPECT" in
    all) return 0 ;;
    linux)
      case "$slice" in
        web|cli) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    auto)
      # Expected only when tools exist — caller checks tools first.
      return 1
      ;;
    *)
      log "FAIL: unknown EMBEDDED_SMOKE_EXPECT=$EXPECT (use linux|all|auto)"
      exit 1
      ;;
  esac
}

require_traverse() {
  if [ ! -d "$TRAVERSE_REPO/examples/traverse-starter" ]; then
    if slice_expected web || slice_expected cli || [ "$EXPECT" = all ]; then
      fail "TRAVERSE_REPO missing examples/traverse-starter: $TRAVERSE_REPO"
      return 1
    fi
    skip "TRAVERSE_REPO not set/usable — $*"
    return 1
  fi
  return 0
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Verify committed digest-pinned runtime.wasm matches sibling runtime-release.json.
verify_runtime_digest() {
  local label="$1"
  local dir="$2"
  local wasm="$dir/runtime.wasm"
  local meta="$dir/runtime-release.json"
  if [ ! -f "$wasm" ] || [ ! -f "$meta" ]; then
    fail "$label: missing runtime.wasm or runtime-release.json under $dir"
    return 1
  fi
  local expected
  expected="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["sha256"])' "$meta")"
  local actual
  actual="$(sha256_file "$wasm")"
  if [ "$expected" != "$actual" ]; then
    fail "$label: runtime.wasm digest mismatch expected=$expected actual=$actual"
    return 1
  fi
  ok "$label runtime.wasm digest matches runtime-release.json ($expected)"
}

# ─── slices ──────────────────────────────────────────────────────────────────

SMOKE_PREPARED=0
SMOKE_MANIFEST_PATH=""

prepare_smoke_bundle() {
  if [ "$SMOKE_PREPARED" = "1" ]; then return 0; fi
  log "=== prepare smoke agents + digests ==="
  if ! TRAVERSE_REPO="$TRAVERSE_REPO" bash "$REPO_ROOT/scripts/ci/prepare_embedded_smoke_bundle.sh"; then
    fail "prepare_embedded_smoke_bundle.sh"
    return 1
  fi
  SMOKE_MANIFEST_PATH="$(cat /tmp/app-refs-smoke-manifest-path.txt)"
  SMOKE_PREPARED=1
  ok "smoke agents prepared"
  return 0
}

smoke_web() {
  local slice=web
  if forced_skip "$slice"; then skip "web (EMBEDDED_SMOKE_SKIP)"; return; fi
  if ! command -v node >/dev/null 2>&1; then
    if slice_expected "$slice"; then fail "web expected but node missing"; else skip "web — node not found"; fi
    return
  fi
  if ! command -v rsync >/dev/null 2>&1; then
    if slice_expected "$slice"; then fail "web expected but rsync missing"; else skip "web — rsync not found"; fi
    return
  fi
  if ! require_traverse "web sync"; then return; fi
  if ! prepare_smoke_bundle; then return; fi

  log "=== web (BundleEmbedder + runtime-owned pipeline output) ==="
  if ! node "$REPO_ROOT/scripts/ci/embedded_smoke_web.mjs"; then
    fail "web embedded_smoke_web.mjs"
    return
  fi
  ok "web embedded smoke (runtime-owned output)"
}

smoke_cli() {
  local slice=cli
  if forced_skip "$slice"; then skip "cli (EMBEDDED_SMOKE_SKIP)"; return; fi
  if ! command -v cargo >/dev/null 2>&1; then
    if slice_expected "$slice"; then fail "cli expected but cargo missing"; else skip "cli — cargo not found"; fi
    return
  fi
  if ! require_traverse "cli link"; then return; fi
  if ! prepare_smoke_bundle; then return; fi

  log "=== cli (health + run with runtime-owned output) ==="
  if ! TRAVERSE_REPO="$TRAVERSE_REPO" bash "$REPO_ROOT/scripts/ci/phase2_link_traverse.sh"; then
    fail "cli phase2_link_traverse.sh"
    return
  fi

  local health
  if ! health="$(
    cd "$REPO_ROOT/apps/traverse-starter" &&
      TRAVERSE_STARTER_MANIFEST="$SMOKE_MANIFEST_PATH" \
        cargo run -q -p traverse-starter-cli -- health --json 2>/dev/null
  )"; then
    fail "cli health command failed"
    return
  fi
  local status mode
  status="$(printf '%s' "$health" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))')"
  mode="$(printf '%s' "$health" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("runtime_mode",""))')"
  if [ "$status" != "Ready" ] || [ "$mode" != "Embedded" ]; then
    fail "cli health expected Embedded/Ready, got: $health"
    return
  fi
  ok "cli embedded health Ready"

  local run_json
  if ! run_json="$(
    cd "$REPO_ROOT/apps/traverse-starter" &&
      TRAVERSE_STARTER_MANIFEST="$SMOKE_MANIFEST_PATH" \
        cargo run -q -p traverse-starter-cli -- run \
          --note "Meeting with design team about onboarding flow improvements" \
          --json 2>/dev/null
  )"; then
    fail "cli run command failed"
    return
  fi
  if ! printf '%s' "$run_json" | python3 -c '
import json,sys
data=json.load(sys.stdin)
out=data.get("output") or {}
proc=out.get("process") or {}
val=out.get("validate") or {}
summ=out.get("summarize") or {}
assert isinstance(val.get("valid"), bool), data
assert isinstance(val.get("issues"), list), data
assert isinstance(proc.get("title"), str) and proc["title"], data
assert isinstance(proc.get("tags"), list), data
assert isinstance(proc.get("noteType"), str), data
assert isinstance(proc.get("suggestedNextAction"), str), data
assert isinstance(proc.get("status"), str), data
assert isinstance(summ.get("summary"), str) and summ["summary"], data
assert isinstance(summ.get("wordCount"), (int, float)), data
print("OK: cli runtime-owned output title=%r" % (proc["title"],))
'; then
    fail "cli run missing runtime-owned pipeline fields: $run_json"
    return
  fi
  ok "cli embedded run (runtime-owned output)"
}

# SDK build/test: hard-fail only when the slice is expected for this runner.
# When EXPECT=linux|all scoping excludes a slice, only digests run (below).
sdk_fail_or_skip() {
  local slice="$1"
  local msg="$2"
  if slice_expected "$slice"; then
    fail "$msg"
  else
    skip "$slice — $msg (advisory; not required for EXPECT=$EXPECT)"
  fi
}

smoke_gtk() {
  local slice=gtk
  if forced_skip "$slice"; then skip "gtk (EMBEDDED_SMOKE_SKIP)"; return; fi
  if ! slice_expected "$slice" && [ "$EXPECT" != "auto" ]; then
    skip "gtk SDK tests — not required for EXPECT=$EXPECT"
    return
  fi
  if ! command -v cargo >/dev/null 2>&1; then
    if slice_expected "$slice"; then fail "gtk expected but cargo missing"; else skip "gtk — cargo not found"; fi
    return
  fi
  if ! pkg-config --exists gtk4 2>/dev/null || ! pkg-config --exists libadwaita-1 2>/dev/null; then
    if slice_expected "$slice"; then fail "gtk expected but gtk4/libadwaita missing"; else skip "gtk — gtk4/libadwaita SDK not installed"; fi
    return
  fi
  log "=== gtk (cargo test traverse-starter-gtk) ==="
  if (
    cd "$REPO_ROOT/apps/traverse-starter" &&
      cargo test -q -p traverse-starter-gtk
  ); then
    ok "gtk unit tests"
  else
    sdk_fail_or_skip "$slice" "gtk cargo test failed"
  fi
}

smoke_android() {
  local slice=android
  if forced_skip "$slice"; then skip "android (EMBEDDED_SMOKE_SKIP)"; return; fi

  local assets="$REPO_ROOT/apps/traverse-starter/android-compose/app/src/main/assets/bundles/traverse-starter/runtime"
  verify_runtime_digest "android" "$assets" || true

  # Linux CI often has a partial Android SDK — do not run gradle unless required.
  if ! slice_expected "$slice" && [ "$EXPECT" != "auto" ]; then
    skip "android SDK tests — not required for EXPECT=$EXPECT (digest checked)"
    return
  fi

  if [ ! -x "$REPO_ROOT/apps/traverse-starter/android-compose/gradlew" ]; then
    if slice_expected "$slice"; then fail "android expected but gradlew missing"; else skip "android — gradlew missing"; fi
    return
  fi
  if ! command -v java >/dev/null 2>&1 || [ -z "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ]; then
    if slice_expected "$slice"; then fail "android expected but JDK/Android SDK missing"; else skip "android — JDK or ANDROID_HOME not set"; fi
    return
  fi
  if ! require_traverse "android sync"; then return; fi
  log "=== android (sync + unit tests) ==="
  if ! TRAVERSE_REPO="$TRAVERSE_REPO" bash "$REPO_ROOT/scripts/ci/sync_android_starter_bundle.sh"; then
    sdk_fail_or_skip "$slice" "android sync failed"
    return
  fi
  if (
    cd "$REPO_ROOT/apps/traverse-starter/android-compose" &&
      ./gradlew --quiet testDebugUnitTest
  ); then
    ok "android unit tests"
  else
    sdk_fail_or_skip "$slice" "android gradle testDebugUnitTest failed"
  fi
}

smoke_swift() {
  local slice=swift
  if forced_skip "$slice"; then skip "swift (EMBEDDED_SMOKE_SKIP)"; return; fi

  verify_runtime_digest "ios" \
    "$REPO_ROOT/apps/traverse-starter/ios-swift/TraverseStarter/Resources/bundles/traverse-starter/runtime" || true
  verify_runtime_digest "macos" \
    "$REPO_ROOT/apps/traverse-starter/macos-swift/TraverseStarterMac/Resources/bundles/traverse-starter/runtime" || true

  if ! slice_expected "$slice" && [ "$EXPECT" != "auto" ]; then
    skip "swift SDK tests — not required for EXPECT=$EXPECT (digests checked)"
    return
  fi

  if ! command -v xcodebuild >/dev/null 2>&1 && ! command -v swift >/dev/null 2>&1; then
    if slice_expected "$slice"; then fail "swift expected but xcodebuild/swift missing"; else skip "swift — Xcode/Swift toolchain not found"; fi
    return
  fi
  if [ "$UNAME" != "Darwin" ]; then
    if slice_expected "$slice"; then fail "swift expected but host is not Darwin"; else skip "swift — requires Darwin host"; fi
    return
  fi
  log "=== swift (swift test TraverseCore) ==="
  local pkg="$REPO_ROOT/apps/traverse-starter/ios-swift/TraverseCore"
  if [ -f "$pkg/Package.swift" ]; then
    if (cd "$pkg" && swift test); then
      ok "swift TraverseCore tests"
    else
      sdk_fail_or_skip "$slice" "swift test failed"
    fi
  else
    skip "swift — TraverseCore Package.swift not found for headless test"
  fi
}

smoke_windows() {
  local slice=windows
  if forced_skip "$slice"; then skip "windows (EMBEDDED_SMOKE_SKIP)"; return; fi

  verify_runtime_digest "windows" \
    "$REPO_ROOT/apps/traverse-starter/windows-winui/TraverseStarter/Assets/bundles/traverse-starter/runtime" || true

  if ! slice_expected "$slice" && [ "$EXPECT" != "auto" ]; then
    skip "windows SDK tests — not required for EXPECT=$EXPECT (digest checked)"
    return
  fi

  if ! command -v dotnet >/dev/null 2>&1; then
    if slice_expected "$slice"; then fail "windows expected but dotnet missing"; else skip "windows — dotnet not found"; fi
    return
  fi
  case "$UNAME" in
    MINGW*|MSYS*|CYGWIN*|Windows*) ;;
    *)
      if slice_expected "$slice"; then fail "windows expected but host is not Windows"; else skip "windows — WinUI host requires Windows"; fi
      return
      ;;
  esac
  log "=== windows (dotnet test) ==="
  local sln
  sln="$(find "$REPO_ROOT/apps/traverse-starter/windows-winui" -name '*.sln' | head -n1 || true)"
  if [ -z "$sln" ]; then
    skip "windows — solution not found"
    return
  fi
  if dotnet test "$sln" --nologo; then
    ok "windows dotnet test"
  else
    sdk_fail_or_skip "$slice" "windows dotnet test failed"
  fi
}

# ─── main ────────────────────────────────────────────────────────────────────

log "=== Embedded runtime smoke ==="
log "REPO_ROOT=$REPO_ROOT"
log "TRAVERSE_REPO=$TRAVERSE_REPO"
log "EXPECT=$EXPECT"
log "HOST=$UNAME"
log ""

smoke_web
log ""
smoke_cli
log ""
smoke_gtk
log ""
smoke_android
log ""
smoke_swift
log ""
smoke_windows

log ""
log "=== Summary: pass=$PASS skip=$SKIP fail=$FAIL ==="
if [ "$FAIL" -ne 0 ]; then
  log "FAIL: embedded smoke"
  exit 1
fi
if [ "$PASS" -eq 0 ]; then
  log "FAIL: embedded smoke ran no passing slices (nothing verified)"
  exit 1
fi
log "PASS: embedded smoke"
exit 0
