#!/usr/bin/env bash
# Mode B prepare helper — Spec 520 verified cache supply chain (scaffold).
# Syncs the public registry index; documents library prepare (no App-Refs materialize).
set -euo pipefail

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: set TRAVERSE_REPO to your Traverse checkout" >&2
  exit 1
fi
if [ -z "${TRAVERSE_MCP_CACHE_ROOT:-}" ]; then
  echo "FAIL: set TRAVERSE_MCP_CACHE_ROOT to a host-owned cache directory" >&2
  exit 1
fi

WORKSPACE="${TRAVERSE_WORKSPACE:-local-default}"
mkdir -p "$TRAVERSE_MCP_CACHE_ROOT"

echo "OK: TRAVERSE_REPO=$TRAVERSE_REPO"
echo "OK: TRAVERSE_MCP_CACHE_ROOT=$TRAVERSE_MCP_CACHE_ROOT"
echo "OK: TRAVERSE_WORKSPACE=$WORKSPACE"
echo "OK: Mode B does not use App-Refs sync materialize rewrite (registry_ref stays as-is)"

cd "$TRAVERSE_REPO"
echo "→ registry index sync (network-capable prepare phase)…"
cargo run -p traverse-cli -- registry sync --workspace "$WORKSPACE" --json

cat <<'EOF'

Next (Spec 520 library — no public CLI yet):
  Rust:  traverse_embedder::HostRegistryCache + prepare_registry_dependency
         then resolve_registry_dependency_offline / EmbedderConfig::with_registry_cache
  Web:   prepareRegistryDependency / resolveRegistryDependencyOffline

Cache bytes stay under TRAVERSE_MCP_CACHE_ROOT (host-owned).
Then run: bash serve.sh   # fail-closed until Traverse Mode B host ships (#865)
EOF
