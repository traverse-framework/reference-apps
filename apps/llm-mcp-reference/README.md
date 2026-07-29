# LLM MCP reference façades

Secondary App-References tier: **LLM product façades** that call Traverse **workflows/capabilities** through MCP instead of encoding business logic in prompt “skills”.

Plan: [`docs/llm-reference-apps-plan.md`](../../docs/llm-reference-apps-plan.md)

## Layout

```text
apps/llm-mcp-reference/
  README.md                 ← this file
  shared/
    prompts/system-boundary.md
    workflows/traverse-starter.md
    workflows/meeting-notes.md
  clients/
    claude-desktop/
    claude-code/
    cursor/
    chatgpt/
    grok/
```

## Quick start (Mode A — local MCP stdio)

1. Clone Traverse next to this repo and build/run the MCP server:

```bash
export TRAVERSE_REPO="$(cd ../Traverse && pwd)"   # adjust path
cd "$TRAVERSE_REPO"
cargo run -p traverse-mcp -- stdio
```

2. Point your LLM client at that command using the example config in `clients/<product>/`.
3. Paste `shared/prompts/system-boundary.md` into the agent/system instructions.
4. Follow `shared/workflows/traverse-starter.md` — submit a note via tools; **only display runtime fields**.
5. For transcripts, follow `shared/workflows/meeting-notes.md` — concrete `describe_server` → `execute_entrypoint` → `render_execution_report` sequence for `meeting-notes.process`.

Optional bearer token (execution commands):

```bash
TRAVERSE_MCP_STDIO_BEARER_TOKEN="local-dev-secret" \
  cargo run -p traverse-mcp -- stdio
```

## Boundary

| Allowed in this tree | Forbidden |
|---|---|
| MCP configs, adapter notes, workflow runbooks | Computing title/tags/recommendations in prompts |
| Rendering/summarizing **runtime JSON** for humans | Private Traverse crate imports |
| Linking to registry/`registry_ref` capabilities | Treating HTTP `serve` as the OS-shell production path |

## Validation

```bash
bash scripts/ci/llm_mcp_reference_smoke.sh
```

## Upstream docs

- [MCP stdio server](https://github.com/traverse-framework/Traverse/blob/main/docs/mcp-stdio-server.md)
- [Packaged MCP artifact](https://github.com/traverse-framework/Traverse/blob/main/docs/packaged-traverse-mcp-server-artifact.md)
- [youaskm3 canonical MCP client path](https://github.com/traverse-framework/Traverse/blob/main/docs/youaskm3-canonical-mcp-client-path.md)
