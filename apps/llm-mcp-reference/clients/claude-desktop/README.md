# Claude Desktop — Traverse MCP façade

## Setup

1. Install/build Traverse so `cargo run -p traverse-mcp -- stdio` works.
2. Copy [`mcp.json.example`](mcp.json.example) into Claude Desktop’s MCP config (merge with existing servers).
3. Replace `TRAVERSE_REPO` paths with your absolute Traverse checkout.
4. Add [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md) to the project/custom instructions.
5. Follow [`../../shared/workflows/traverse-starter.md`](../../shared/workflows/traverse-starter.md).
6. For transcripts, follow [`../../shared/workflows/meeting-notes.md`](../../shared/workflows/meeting-notes.md).

## Boundary

Claude must call MCP tools for business outcomes. Do not paste a “skill” that invents title/tags or meeting-notes fields.
