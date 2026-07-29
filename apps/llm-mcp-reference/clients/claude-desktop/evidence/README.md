# Claude Desktop MCP live evidence (`llm-mcp-claude-live-smoke`)

Captured **2026-07-29** against Traverse **v0.8.2**.

## What was proven

[`../mcp.json.example`](../mcp.json.example) launches:

```bash
cargo run -p traverse-mcp -- stdio
```

That exact Mode A command was exercised (JSONL stdio envelopes). Claude Desktop GUI was **not** available in this Linux cloud-agent environment; DoD allows a **command transcript** in lieu of screenshots.

### Files

| File | Contents |
|---|---|
| [`claude-desktop-mcp-stdio-transcript.jsonl`](claude-desktop-mcp-stdio-transcript.jsonl) | `describe_server` → `list_entrypoints` → `list_content_groups` → `shutdown` |
| [`claude-desktop-mcp-execute-transcript.jsonl`](claude-desktop-mcp-execute-transcript.jsonl) | validate → execute → `render_execution_report` on `expedition.planning.plan-expedition` (status valid / completed / rendered) |

## Runtime fields only

Present only fields returned by MCP envelopes / `render_execution_report`. Do not invent title/tags or meeting-notes rows.

## Catalog note

Default `traverse-mcp` catalog on v0.8.2 is the **expedition** bundle. `traverse-starter.*` IDs are not listed yet; the Claude Desktop config still correctly binds to Mode A stdio. See Cursor evidence for the same catalog honesty note.
