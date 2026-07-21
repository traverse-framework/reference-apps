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
#   EMBEDDED_SMOKE_REQUIRE_OUTPUT 1 → fail web/cli if pipeline fields missing (stubs)
#   EMBEDDED_SMOKE_SKIP=<csv>     force-skip slices (web,cli,gtk,android,swift,windows)
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

  log "=== web (BundleEmbedder + NodeFsBundleLoader) ==="
  if ! TRAVERSE_REPO="$TRAVERSE_REPO" bash "$REPO_ROOT/scripts/ci/sync_web_starter_bundle.sh"; then
    fail "web sync_web_starter_bundle.sh"
    return
  fi
  if ! node "$REPO_ROOT/scripts/ci/embedded_smoke_web.mjs"; then
    fail "web embedded_smoke_web.mjs"
    return
  fi
  ok "web embedded smoke"
}

smoke_cli() {
  local slice=cli
  if forced_skip "$slice"; then skip "cli (EMBEDDED_SMOKE_SKIP)"; return; fi
  if ! command -v cargo >/dev/null 2>&1; then
    if slice_expected "$slice"; then fail "cli expected but cargo missing"; else skip "cli — cargo not found"; fi
    return
  fi
  if ! require_traverse "cli link"; then return; fi

  log "=== cli (traverse-starter-cli health) ==="
  if ! TRAVERSE_REPO="$TRAVERSE_REPO" bash "$REPO_ROOT/scripts/ci/phase2_link_traverse.sh"; then
    fail "cli phase2_link_traverse.sh"
    return
  fi

  local health
  if ! health="$(
    cd "$REPO_ROOT/apps/traverse-starter" &&
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
}

smoke_gtk() {
  local slice=gtk
  if forced_skip "$slice"; then skip "gtk (EMBEDDED_SMOKE_SKIP)"; return; fi
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
    fail "gtk cargo test"
  fi
}

smoke_android() {
  local slice=android
  if forced_skip "$slice"; then skip "android (EMBEDDED_SMOKE_SKIP)"; return; fi

  local assets="$REPO_ROOT/apps/traverse-starter/android-compose/app/src/main/assets/bundles/traverse-starter/runtime"
  verify_runtime_digest "android" "$assets" || true

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
    fail "android sync"
    return
  fi
  if (
    cd "$REPO_ROOT/apps/traverse-starter/android-compose" &&
      ./gradlew --quiet testDebugUnitTest
  ); then
    ok "android unit tests"
  else
    fail "android gradle testDebugUnitTest"
  fi
}

smoke_swift() {
  local slice=swift
  if forced_skip "$slice"; then skip "swift (EMBEDDED_SMOKE_SKIP)"; return; fi

  verify_runtime_digest "ios" \
    "$REPO_ROOT/apps/traverse-starter/ios-swift/TraverseStarter/Resources/bundles/traverse-starter/runtime" || true
  verify_runtime_digest "macos" \
    "$REPO_ROOT/apps/traverse-starter/macos-swift/TraverseStarterMac/Resources/bundles/traverse-starter/runtime" || true

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
      fail "swift test"
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
    fail "windows dotnet test"
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
