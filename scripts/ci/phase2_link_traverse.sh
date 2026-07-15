#!/usr/bin/env bash
# Ensures manifests/<app>/_traverse symlinks point at TRAVERSE_REPO.
# Required for app validate/register — WASM, contracts, and workflows live in Traverse.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"

if [ -z "${TRAVERSE_REPO:-}" ]; then
  echo "FAIL: TRAVERSE_REPO is not set."
  echo ""
  echo "Clone Traverse main (with traverse-starter + doc-approval examples) and export:"
  echo "  export TRAVERSE_REPO=/path/to/Traverse"
  exit 1
fi

if [ ! -d "$TRAVERSE_REPO" ]; then
  echo "FAIL: TRAVERSE_REPO does not exist: $TRAVERSE_REPO"
  exit 1
fi

if [ ! -f "$TRAVERSE_REPO/examples/traverse-starter/process-agent/artifacts/process-agent.wasm" ]; then
  echo "FAIL: traverse-starter WASM not found in TRAVERSE_REPO."
  exit 1
fi

if [ ! -f "$TRAVERSE_REPO/examples/doc-approval/analyze-agent/artifacts/analyze-agent.wasm" ]; then
  echo "FAIL: doc-approval WASM not found in TRAVERSE_REPO."
  echo "      Ensure TRAVERSE_REPO includes issue #555 recommend + analyze agents."
  exit 1
fi

link_app() {
  local app="$1"
  local link="$REPO_ROOT/manifests/$app/_traverse"
  mkdir -p "$(dirname "$link")"
  ln -sfn "$TRAVERSE_REPO" "$link"
  echo "OK: linked $link -> $TRAVERSE_REPO"
}

link_app "traverse-starter"
link_app "doc-approval"
