# Claude Desktop — Traverse MCP façade

## Setup

1. Install/build Traverse so `cargo run -p traverse-mcp -- stdio` works (tested **v0.8.2+**).
2. Copy [`mcp.json.example`](mcp.json.example) into Claude Desktop’s MCP config (merge with existing servers).
3. Replace `/ABS/PATH/TO/Traverse` with your **absolute** Traverse checkout in both `cwd` and `env.TRAVERSE_REPO`.
4. Add [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md) to the project/custom instructions.
5. Follow [`../../shared/workflows/traverse-starter.md`](../../shared/workflows/traverse-starter.md) when starter entrypoints appear in `list_entrypoints`; until then discover via MCP and render runtime fields only.
6. For transcripts, follow [`../../shared/workflows/meeting-notes.md`](../../shared/workflows/meeting-notes.md) once `meeting-notes.process` is catalogued.

## Live evidence

See [`evidence/`](evidence/) — Mode A stdio command transcripts matching `mcp.json.example` (`llm-mcp-claude-live-smoke`).

## Boundary

Claude must call MCP tools for business outcomes. Do not paste a “skill” that invents title/tags or meeting-notes fields.
