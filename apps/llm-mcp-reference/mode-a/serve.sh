#!/usr/bin/env bash
# Mode A MCP launcher — fail closed until Traverse ships Spec 119 public-registry host.
# Do NOT silently fall back to expedition stdio (would mislabel kit catalog).
set -euo pipefail

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: set TRAVERSE_REPO" >&2
  exit 1
fi
if [ -z "${TRAVERSE_MCP_CACHE_ROOT:-}" ]; then
  echo "FAIL: set TRAVERSE_MCP_CACHE_ROOT (Spec 119 host-supplied verified state)" >&2
  exit 1
fi

cd "$TRAVERSE_REPO"

# Probe for a future Mode A entrypoint without inventing one.
if cargo run -p traverse-mcp -- --help 2>/dev/null | grep -Eqi 'mode-a|verified-registry|public-registry'; then
  echo "OK: Mode A-looking traverse-mcp help found — wire serve.sh to the shipped flags and re-run."
  echo "HINT: Spec 119 wants a versioned traverse-mcp binary + prepared verified state (FR-006)."
  echo "HINT: cache root configured: $TRAVERSE_MCP_CACHE_ROOT"
  exit 2
fi

cat <<EOF >&2
FAIL: Spec 119 Mode A host not yet shipped in Traverse.
  Public-only discovery + inline RuntimeRequest + digest-verified WASM are not
  the default \`traverse-mcp -- stdio\` expedition catalog.
  Governing spec: https://github.com/traverse-framework/Traverse/blob/main/specs/119-verified-registry-mcp-mode-a/spec.md
  App-Refs live kit execute stays on ticket llm-mcp-traverse-starter-catalog.
  Expedition bootstrap (not Spec 119): cargo run -p traverse-mcp -- stdio
  Cache root configured: $TRAVERSE_MCP_CACHE_ROOT
EOF
exit 2
