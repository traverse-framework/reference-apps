# Claude Code MCP live evidence (`llm-mcp-claude-live-smoke`)

Captured **2026-07-29** against Traverse **v0.8.2**.

## What was proven

[`.mcp.json.example`](../.mcp.json.example) launches the same Mode A command as Claude Desktop:

```bash
cargo run -p traverse-mcp -- stdio
```

Command transcripts (Claude Code CLI GUI not required for this evidence):

| File | Contents |
|---|---|
| [`claude-code-mcp-stdio-transcript.jsonl`](claude-code-mcp-stdio-transcript.jsonl) | discovery + shutdown |
| [`claude-code-mcp-execute-transcript.jsonl`](claude-code-mcp-execute-transcript.jsonl) | validate → execute → render on `expedition.planning.plan-expedition` |

## Runtime fields only

Do not invent business fields; render MCP/runtime output only.

## Catalog note

Same as Desktop: default catalog is expedition until starter/meeting-notes entrypoints are published to MCP.
