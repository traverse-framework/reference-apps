# Claude Desktop MCP Mode A evidence (`llm-mcp-traverse-starter-catalog`)

Captured **2026-09-07** against Traverse **main** (Spec 119 Mode A via [#1252](https://github.com/traverse-framework/Traverse/pull/1252)).

Same Mode A verified-public catalog path as Cursor evidence (stdio JSONL envelopes). Claude Desktop GUI was not required; DoD allows a **command transcript**.

### transcript A — discovery

[`claude-desktop-mcp-stdio-transcript.jsonl`](claude-desktop-mcp-stdio-transcript.jsonl) — `verified_public` + `core.normalize-participants`.

### transcript B — execute / render

[`claude-desktop-mcp-execute-transcript.jsonl`](claude-desktop-mcp-execute-transcript.jsonl) — inline execute + render, `digest_matches_public_state:true`.

See [`../../cursor/evidence/README.md`](../../cursor/evidence/README.md) for env/reproduce details and fail-closed notes.
