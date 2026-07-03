#!/usr/bin/env bash
# Ensures manifests/traverse-starter/_traverse symlink points at TRAVERSE_REPO.
# Required for app validate/register — WASM, contracts, and workflows live in Traverse.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
LINK="$REPO_ROOT/manifests/traverse-starter/_traverse"

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: TRAVERSE_REPO is not set."
  echo ""
  echo "Clone Traverse main (v0.5.0+ with traverse-starter example) and export:"
  echo "  export TRAVERSE_REPO=/path/to/Traverse"
  exit 1
fi

if [ ! -d "$TRAVERSE_REPO" ]; then
  echo "FAIL: TRAVERSE_REPO does not exist: $TRAVERSE_REPO"
  exit 1
fi

if [ ! -f "$TRAVERSE_REPO/examples/traverse-starter/process-agent/artifacts/process-agent.wasm" ]; then
  echo "FAIL: traverse-starter WASM not found in TRAVERSE_REPO."
  echo "      Ensure TRAVERSE_REPO is Traverse main with issue #499 merged."
  exit 1
fi

mkdir -p "$(dirname "$LINK")"
ln -sfn "$TRAVERSE_REPO" "$LINK"
echo "OK: linked $LINK -> $TRAVERSE_REPO"
