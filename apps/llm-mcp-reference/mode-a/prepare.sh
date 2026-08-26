#!/usr/bin/env bash
# Mode A prepare helper — Spec 119 host-supplied verified public registry state.
# Syncs the public registry index; documents prepare. No App-Refs materialize.
set -euo pipefail

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: set TRAVERSE_REPO to your Traverse checkout" >&2
  exit 1
fi
if [ -z "${TRAVERSE_MCP_CACHE_ROOT:-}" ]; then
  echo "FAIL: set TRAVERSE_MCP_CACHE_ROOT to a host-owned verified-state directory" >&2
  exit 1
fi

WORKSPACE="${TRAVERSE_WORKSPACE:-local-default}"
mkdir -p "$TRAVERSE_MCP_CACHE_ROOT"

echo "OK: TRAVERSE_REPO=$TRAVERSE_REPO"
echo "OK: TRAVERSE_MCP_CACHE_ROOT=$TRAVERSE_MCP_CACHE_ROOT"
echo "OK: TRAVERSE_WORKSPACE=$WORKSPACE"
echo "OK: Mode A does not use App-Refs sync materialize rewrite (registry_ref stays as-is)"

cd "$TRAVERSE_REPO"
echo "→ registry index sync (network-capable prepare phase only)…"
cargo run -p traverse-cli -- registry sync --workspace "$WORKSPACE" --json

cat <<'EOF'

Next (Spec 119 — no public one-liner CLI for Mode A serve yet):
  Prepare host-supplied digest-verified public registry state into
  TRAVERSE_MCP_CACHE_ROOT (Spec 118 ownership + Spec 119 Mode A).
  Discovery/execute MUST NOT refresh from the network.
  Inline RuntimeRequest JSON xor request_path (FR-002).
  No kit content groups in v1 (FR-007).

Then run: bash serve.sh   # fail-closed until Traverse Mode A host ships
EOF
