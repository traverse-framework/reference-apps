#!/usr/bin/env bash
# Scaffold integrity smoke for LLM MCP reference façades (secondary tier).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0
need() {
  if [ ! -e "$ROOT/$1" ]; then
    echo "FAIL: missing $1"
    fail=1
  else
    echo "OK:   $1"
  fi
}
need docs/llm-reference-apps-plan.md
need apps/llm-mcp-reference/README.md
need apps/llm-mcp-reference/shared/prompts/system-boundary.md
need apps/llm-mcp-reference/shared/workflows/traverse-starter.md
need apps/llm-mcp-reference/shared/workflows/meeting-notes.md
need apps/llm-mcp-reference/clients/claude-desktop/README.md
need apps/llm-mcp-reference/clients/claude-desktop/mcp.json.example
need apps/llm-mcp-reference/clients/claude-code/README.md
need apps/llm-mcp-reference/clients/claude-code/.mcp.json.example
need apps/llm-mcp-reference/clients/cursor/README.md
need apps/llm-mcp-reference/clients/cursor/mcp.json.example
need apps/llm-mcp-reference/clients/chatgpt/README.md
need apps/llm-mcp-reference/clients/grok/README.md
# Configs must mention traverse-mcp, not invent business fields
if ! rg -q 'traverse-mcp' "$ROOT/apps/llm-mcp-reference/clients/claude-desktop/mcp.json.example"; then
  echo "FAIL: claude-desktop mcp example must reference traverse-mcp"
  fail=1
fi
if rg -n -i 'invent (title|tags)|compute business' "$ROOT/apps/llm-mcp-reference/shared/prompts/system-boundary.md" >/dev/null; then
  : # optional; boundary doc forbids inventing — ensure forbid language exists
fi
if ! rg -q 'do not invent' "$ROOT/apps/llm-mcp-reference/shared/prompts/system-boundary.md"; then
  echo "FAIL: system-boundary.md must forbid inventing fields"
  fail=1
fi
if [ "$fail" -ne 0 ]; then
  echo "llm_mcp_reference_smoke: FAILED"
  exit 1
fi
echo "llm_mcp_reference_smoke: PASS"
