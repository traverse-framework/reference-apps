# Claude Code — Traverse MCP façade

## Setup

1. Ensure Traverse builds: `cargo run -p traverse-mcp -- stdio` from the Traverse root (tested **v0.8.2+**).
2. Copy [`.mcp.json.example`](.mcp.json.example) to your project or user MCP config as supported by Claude Code.
3. Set **absolute** `cwd` / `TRAVERSE_REPO` (replace `/ABS/PATH/TO/Traverse`).
4. Load [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md).
5. Run [`../../shared/workflows/traverse-starter.md`](../../shared/workflows/traverse-starter.md) when starter IDs are in the MCP catalog; otherwise use `list_entrypoints` and render runtime fields only.
6. For transcripts, follow [`../../shared/workflows/meeting-notes.md`](../../shared/workflows/meeting-notes.md).

## Live evidence

See [`evidence/`](evidence/) — Mode A stdio transcripts for the same command as `.mcp.json.example` (`llm-mcp-claude-live-smoke`).

Companion authoring skill (contracts only — not product business logic):  
https://github.com/traverse-framework/claude-skills
