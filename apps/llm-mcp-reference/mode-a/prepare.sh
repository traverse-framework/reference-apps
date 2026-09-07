#!/usr/bin/env bash
# Mode A prepare helper — Spec 119 host-supplied verified public registry state.
# Seeds a digest-verified HostRegistryCache for Mode A serve. No App-Refs materialize.
set -euo pipefail

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: set TRAVERSE_REPO to your Traverse checkout" >&2
  exit 1
fi

CACHE_ROOT="${TRAVERSE_MCP_REGISTRY_CACHE:-${TRAVERSE_MCP_CACHE_ROOT:-}}"
if [ -z "$CACHE_ROOT" ]; then
  echo "FAIL: set TRAVERSE_MCP_REGISTRY_CACHE (or TRAVERSE_MCP_CACHE_ROOT alias)" >&2
  exit 1
fi

WORKSPACE="${TRAVERSE_WORKSPACE:-local-default}"
FIXTURE="${TRAVERSE_REPO}/crates/traverse-mcp/tests/fixtures/mode-a-cache"

if [ ! -f "$FIXTURE/public-metadata/current.json" ]; then
  cat <<EOF >&2
FAIL: Traverse Mode A fixture missing at
  $FIXTURE
  Need Traverse main with Spec 119 (#1241 / #1252) checked out.
  Regenerate upstream with:
    cargo test -p traverse-mcp --lib -- --ignored --exact stdio_server::tests::mode_a::regenerate_committed_fixture
EOF
  exit 1
fi

mkdir -p "$CACHE_ROOT"
# Copy the committed verified kit fixture (includes core.normalize-participants —
# a Loop WF1 registry dependency used by App-Refs). Hosts may later extend the
# same HostRegistryCache shape with additional published registry_refs via
# traverse_embedder::prepare_registry_dependency + publish_public_metadata.
rsync -a --delete "$FIXTURE/" "$CACHE_ROOT/"

echo "OK: TRAVERSE_REPO=$TRAVERSE_REPO"
echo "OK: TRAVERSE_MCP_REGISTRY_CACHE=$CACHE_ROOT"
echo "OK: TRAVERSE_WORKSPACE=$WORKSPACE"
echo "OK: seeded Mode A verified cache from Traverse mode-a-cache fixture"
echo "OK: Mode A does not use App-Refs sync materialize rewrite (registry_ref stays as-is)"

# Optional: keep local public index in sync for hosts that extend the cache.
if [ "${TRAVERSE_MCP_PREPARE_SYNC:-0}" = "1" ]; then
  cd "$TRAVERSE_REPO"
  echo "→ registry index sync (network-capable prepare phase only)…"
  cargo run -q -p traverse-cli -- registry sync --workspace "$WORKSPACE" --json
fi

cat <<EOF

Prepared verified state at:
  $CACHE_ROOT/public-metadata/current.json

Default seeded kit (App-Refs Loop WF1 dependency):
  core.normalize-participants @ 1.1.0

Then run: bash serve.sh
Do NOT use bare \`cargo run -p traverse-mcp -- stdio\` without
TRAVERSE_MCP_REGISTRY_CACHE — that is expedition bootstrap, not Spec 119.
EOF
