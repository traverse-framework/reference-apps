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
need apps/llm-mcp-reference/clients/claude-desktop/evidence/README.md
need apps/llm-mcp-reference/clients/claude-desktop/evidence/claude-desktop-mcp-stdio-transcript.jsonl
need apps/llm-mcp-reference/clients/claude-desktop/evidence/claude-desktop-mcp-execute-transcript.jsonl
need apps/llm-mcp-reference/clients/claude-code/README.md
need apps/llm-mcp-reference/clients/claude-code/.mcp.json.example
need apps/llm-mcp-reference/clients/claude-code/evidence/README.md
need apps/llm-mcp-reference/clients/claude-code/evidence/claude-code-mcp-stdio-transcript.jsonl
need apps/llm-mcp-reference/clients/claude-code/evidence/claude-code-mcp-execute-transcript.jsonl
need apps/llm-mcp-reference/clients/cursor/README.md
need apps/llm-mcp-reference/clients/cursor/mcp.json.example
need apps/llm-mcp-reference/clients/cursor/evidence/README.md
need apps/llm-mcp-reference/clients/cursor/evidence/cursor-mcp-stdio-transcript.jsonl
need apps/llm-mcp-reference/clients/cursor/evidence/cursor-mcp-execute-transcript.jsonl
need apps/llm-mcp-reference/clients/chatgpt/README.md
need apps/llm-mcp-reference/clients/grok/README.md
# Mode B scaffold (Spec 520 prepare/cache — fail-closed until Traverse host ships)
need apps/llm-mcp-reference/mode-b/README.md
need apps/llm-mcp-reference/mode-b/mcp.json.example
need apps/llm-mcp-reference/mode-b/prepare-cache.sh
need apps/llm-mcp-reference/mode-b/serve.sh
if ! rg -q 'TRAVERSE_MCP_CACHE_ROOT' "$ROOT/apps/llm-mcp-reference/mode-b/mcp.json.example"; then
  echo "FAIL: mode-b mcp example must set TRAVERSE_MCP_CACHE_ROOT"
  fail=1
fi
if ! rg -q 'HostRegistryCache|prepare_registry_dependency|Spec 520' "$ROOT/apps/llm-mcp-reference/mode-b/README.md"; then
  echo "FAIL: mode-b README must document Spec 520 prepare/cache APIs"
  fail=1
fi
if ! rg -qi 'not yet shipped|Mode B host not yet|fail' "$ROOT/apps/llm-mcp-reference/mode-b/serve.sh"; then
  echo "FAIL: mode-b serve.sh must fail closed until Traverse Mode B host ships"
  fail=1
fi
if rg -q 'APP_REFS_MATERIALIZE_REGISTRY_REFS|sync_bundle_materialize_registry_refs' "$ROOT/apps/llm-mcp-reference/mode-b"; then
  echo "FAIL: mode-b must not depend on App-Refs materialize rewrite"
  fail=1
fi
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
# meeting-notes runbook must document concrete MCP tool sequence
MN="$ROOT/apps/llm-mcp-reference/shared/workflows/meeting-notes.md"
for needle in 'meeting-notes.process' 'describe_server' 'list_entrypoints' 'execute_entrypoint' 'render_execution_report' 'action_items'; do
  if ! rg -q "$needle" "$MN"; then
    echo "FAIL: meeting-notes.md must mention $needle"
    fail=1
  fi
done
if [ "$fail" -ne 0 ]; then
  echo "llm_mcp_reference_smoke: FAILED"
  exit 1
fi
echo "llm_mcp_reference_smoke: PASS"
