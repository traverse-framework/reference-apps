# Cursor — Traverse MCP façade

## Setup

1. Traverse checkout that includes Spec 119 Mode A (post [#1252](https://github.com/traverse-framework/Traverse/pull/1252), or the next release after `v0.10.0`).
2. Prepare a verified cache: `cd ../../mode-a && bash prepare.sh` (sets `TRAVERSE_MCP_REGISTRY_CACHE`).
3. Copy [`mcp.json.example`](mcp.json.example) into Cursor MCP settings (or use [`../../mode-a/mcp.json.example`](../../mode-a/mcp.json.example)).
4. Replace absolute paths for `TRAVERSE_REPO` and `TRAVERSE_MCP_REGISTRY_CACHE`.
5. Apply [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md) in rules/instructions.
6. Discover via `list_entrypoints` and only render runtime fields. Seeded fixture includes `core.normalize-participants` (Loop WF1). Extend the cache for `meeting-notes.process` / `traverse-starter.process` when needed.

## Live evidence

See [`evidence/`](evidence/) — Mode A verified-public discovery + inline execute/render (`llm-mcp-traverse-starter-catalog`).

## Boundary

Cursor agents working **in this repo** still claim OS tickets via `AGENTS.md`; this façade is for **product** workflows through Traverse MCP, not for replacing Project 2 claim locks.
