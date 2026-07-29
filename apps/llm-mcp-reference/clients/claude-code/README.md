# Claude Code — Traverse MCP façade

## Setup

1. Ensure Traverse builds: `cargo run -p traverse-mcp -- stdio` from the Traverse root.
2. Copy [`.mcp.json.example`](.mcp.json.example) to your project or user MCP config as supported by Claude Code.
3. Set absolute `cwd` / `TRAVERSE_REPO`.
4. Load [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md).
5. Run [`../../shared/workflows/traverse-starter.md`](../../shared/workflows/traverse-starter.md).

Companion authoring skill (contracts only — not product business logic):  
https://github.com/traverse-framework/claude-skills
