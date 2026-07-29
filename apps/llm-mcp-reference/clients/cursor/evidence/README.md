# Cursor MCP live evidence (`llm-mcp-cursor-live-smoke`)

Captured **2026-07-29** against Traverse **v0.8.2** (`TRAVERSE_REPO=/tmp/Traverse`).

## What was proven

The Cursor façade config in [`../mcp.json.example`](../mcp.json.example) launches:

```bash
cargo run -p traverse-mcp -- stdio
```

with `cwd` / `TRAVERSE_REPO` pointing at a Traverse checkout. That exact command was exercised here (stdio JSONL envelopes, local_trust Mode A).

### Transcript A — discovery

File: [`cursor-mcp-stdio-transcript.jsonl`](cursor-mcp-stdio-transcript.jsonl)

Commands: `describe_server` → `list_entrypoints` → `list_content_groups` → `shutdown`

Observed kinds: `mcp_stdio_server_startup` (ready), `mcp_stdio_server_description`, `mcp_stdio_server_entrypoint_list`, `mcp_stdio_server_content_group_list`, `mcp_stdio_server_shutdown`.

### transcript B — validate / execute / render

File: [`cursor-mcp-execute-transcript.jsonl`](cursor-mcp-execute-transcript.jsonl)

Commands follow the upstream `mcp_stdio_server_execution_report_smoke.sh` path against the **current** MCP catalog workflow `expedition.planning.plan-expedition` (request_path `examples/expedition/runtime-requests/plan-expedition.json`).

Observed: validation `valid` → execution `completed` → report `rendered` → shutdown `complete`. stderr empty.

## Runtime fields only

Execution/report envelopes come from Traverse MCP — this façade does **not** invent structured business fields. Agents must present only fields returned by `render_execution_report` / execution envelopes.

## Catalog note (honest)

As of Traverse v0.8.2, `traverse-mcp stdio`’s default governed catalog is the **expedition** registry bundle (plus `core-runtime-example` content group). **`traverse-starter.*` / `meeting-notes.process` entrypoints are not listed yet** in that default catalog.

Implication for App-Refs:

- Cursor MCP config is correct for Mode A (stdio → `traverse-mcp`).
- Live product smoke against starter/meeting-notes **IDs** lands when those capabilities are published into the MCP catalog (or a documented catalog override ships upstream). Until then, this evidence proves the Cursor→MCP host path end-to-end on the catalog the server actually serves.

## Reproduce

```bash
export TRAVERSE_REPO=/absolute/path/to/Traverse
cd "$TRAVERSE_REPO"
printf '%s\n' \
  '{"command":"describe_server"}' \
  '{"command":"list_entrypoints"}' \
  '{"command":"shutdown"}' \
  | cargo run -q -p traverse-mcp -- stdio
```

Optional full execute path: see Traverse `scripts/ci/mcp_stdio_server_execution_report_smoke.sh`.
