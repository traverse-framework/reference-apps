# Cursor — Traverse MCP façade

## Setup

1. Traverse checkout with working `traverse-mcp` (tested with **v0.8.2+**).
2. Copy [`mcp.json.example`](mcp.json.example) into Cursor MCP settings (Cursor Settings → MCP, or project MCP config as applicable).
3. Replace `/ABS/PATH/TO/Traverse` with your **absolute** Traverse checkout in both `cwd` and `env.TRAVERSE_REPO`.
4. Apply [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md) in rules/instructions.
5. Exercise [`../../shared/workflows/traverse-starter.md`](../../shared/workflows/traverse-starter.md) when starter entrypoints are available in the MCP catalog; until then use discovery (`list_entrypoints`) and only render runtime fields.
6. For meeting transcripts, follow [`../../shared/workflows/meeting-notes.md`](../../shared/workflows/meeting-notes.md) (tool sequence + sample transcript) once `meeting-notes.process` is catalogued.

## Live evidence

See [`evidence/`](evidence/) — Cursor cloud agent ran the **same** `cargo run -p traverse-mcp -- stdio` command as `mcp.json.example` and captured discovery + execute/render transcripts (`llm-mcp-cursor-live-smoke`).

## Boundary

Cursor agents working **in this repo** still claim OS tickets via `AGENTS.md`; this façade is for **product** workflows through Traverse MCP, not for replacing Project 2 claim locks.
