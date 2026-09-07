#!/usr/bin/env bash
# Mode A MCP launcher — Spec 119 verified public-registry host.
# Do NOT silently fall back to expedition stdio (would mislabel kit catalog).
set -euo pipefail

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: set TRAVERSE_REPO" >&2
  exit 1
fi

# Canonical Traverse env is TRAVERSE_MCP_REGISTRY_CACHE (Spec 119).
# TRAVERSE_MCP_CACHE_ROOT remains accepted as an App-Refs alias.
CACHE_ROOT="${TRAVERSE_MCP_REGISTRY_CACHE:-${TRAVERSE_MCP_CACHE_ROOT:-}}"
if [ -z "$CACHE_ROOT" ]; then
  echo "FAIL: set TRAVERSE_MCP_REGISTRY_CACHE (or TRAVERSE_MCP_CACHE_ROOT alias)" >&2
  exit 1
fi
if [ ! -f "$CACHE_ROOT/public-metadata/current.json" ]; then
  cat <<EOF >&2
FAIL: Mode A cache is not prepared verified public state.
  Missing: $CACHE_ROOT/public-metadata/current.json
  Run: bash prepare.sh
  Unprepared/malformed state must fail closed (Spec 119 FR-003) — never expedition fallback.
EOF
  exit 2
fi

cd "$TRAVERSE_REPO"
export TRAVERSE_MCP_REGISTRY_CACHE="$CACHE_ROOT"

# Contributor source-run (FR-006 prefers a versioned binary when published).
# Expedition stdio without TRAVERSE_MCP_REGISTRY_CACHE is intentionally not used here.
exec cargo run -q -p traverse-mcp -- stdio "$@"
