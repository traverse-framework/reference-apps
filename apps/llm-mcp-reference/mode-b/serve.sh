#!/usr/bin/env bash
# Mode B MCP launcher — fail closed until Traverse ships an embedded/cache host.
# Do NOT silently fall back to Mode A expedition stdio (would mislabel Mode B).
set -euo pipefail

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: set TRAVERSE_REPO" >&2
  exit 1
fi
if [ -z "${TRAVERSE_MCP_CACHE_ROOT:-}" ]; then
  echo "FAIL: set TRAVERSE_MCP_CACHE_ROOT (Spec 520 host-owned verified cache)" >&2
  exit 1
fi

cd "$TRAVERSE_REPO"

# Probe for a future Mode B entrypoint without inventing one.
if cargo run -p traverse-mcp -- --help 2>/dev/null | grep -Eqi 'embedded|cache-root|mode-b'; then
  echo "OK: Mode B-looking traverse-mcp help found — wire serve.sh to the shipped flags and re-run."
  echo "HINT: intended shape: cargo run -p traverse-mcp -- embedded --cache-root \"\$TRAVERSE_MCP_CACHE_ROOT\""
  exit 2
fi

cat <<EOF >&2
FAIL: Mode B host not yet shipped in Traverse.
  Spec 520 prepare/cache libraries exist (#860); MCP embedded/cache serve does not.
  Track: https://github.com/traverse-framework/Traverse/issues/865
  Use Mode A for a runnable path: cargo run -p traverse-mcp -- stdio
  Cache root configured: $TRAVERSE_MCP_CACHE_ROOT
EOF
exit 2
