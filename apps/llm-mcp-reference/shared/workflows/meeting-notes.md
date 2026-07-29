# Workflow runbook — meeting-notes

Equivalent to the **meeting-notes** OS shell: paste a transcript; show runtime-owned **action items**, **decisions**, **follow-ups**, and **summary**.

OS twins: [`apps/meeting-notes/`](../../../meeting-notes/) (Web / iOS / macOS / Android / Windows / Linux / CLI).

## Capability / workflow

| Field | Value |
|---|---|
| App id | `meeting-notes` |
| Workflow / capability | `meeting-notes.process` |
| Input | `{ "transcript": "<string>" }` (max length mirrors shells: **5000**) |
| Runtime-owned output | `action_items[]`, `decisions[]`, `follow_ups[]`, `summary` |

Discover this entrypoint through `traverse-mcp` — do **not** hard-code private crate paths. Prefer the **governed workflow/entrypoint** the server lists for `meeting-notes.process`.

## Prerequisites (Mode A)

1. Traverse checkout with working `traverse-mcp` (see [MCP stdio server](https://github.com/traverse-framework/Traverse/blob/main/docs/mcp-stdio-server.md)).
2. Client MCP config from `clients/<product>/` pointing at:

```bash
cargo run -p traverse-mcp -- stdio
```

3. System instructions include [`../prompts/system-boundary.md`](../prompts/system-boundary.md).

Optional bearer token for execution commands:

```bash
TRAVERSE_MCP_STDIO_BEARER_TOKEN="local-dev-secret" \
  cargo run -p traverse-mcp -- stdio
```

Pass the same token on `execute_entrypoint` / `render_execution_report` as `auth.bearer` or `bearer_token` when required.

## Concrete MCP tool sequence

Use the public stdio command surface in order:

| Step | Tool | Purpose |
|---|---|---|
| 1 | `describe_server` | Confirm MCP is up and Mode A local trust is available |
| 2 | `list_content_groups` → `describe_content_group` | Orient on governed content (when groups are present) |
| 3 | `list_entrypoints` | Find the entrypoint whose id/name maps to **`meeting-notes.process`** |
| 4 | `describe_entrypoint` | Confirm input expects a **transcript** (or equivalent payload field) |
| 5 | `validate_entrypoint` | Validate payload shape before execute |
| 6 | `execute_entrypoint` | Submit `{ "transcript": "…" }` (or the schema field `describe_entrypoint` documents) |
| 7 | `render_execution_report` | Present the public execution report / structured output |

### Example agent checklist (copy into a session)

```text
1. Call describe_server.
2. Call list_entrypoints; select meeting-notes.process (or the entrypoint that wraps it).
3. Call describe_entrypoint on that id; note required input fields.
4. Call validate_entrypoint with a short transcript payload.
5. Call execute_entrypoint with the same payload.
6. Call render_execution_report for the returned execution.
7. Show ONLY runtime fields: action_items, decisions, follow_ups, summary.
   If a field is missing, say it is missing — do not invent tasks or decisions.
```

### Sample transcript (for live smoke)

```text
Alex: We need Wave 2 ports for iOS and Android by Friday.
Sam: Agreed — I'll own the Android Compose shell.
Alex: Decision: use the embedded runtime path only, no sidecar.
```

Expected **shape** (values come from the runtime, not this runbook):

```json
{
  "action_items": [{ "task": "…", "owner": "…", "due": "…" }],
  "decisions": [{ "text": "…", "made_by": "…" }],
  "follow_ups": ["…"],
  "summary": "…"
}
```

## Success looks like

Same as the Web shell ([`MeetingResult`](../../../meeting-notes/web-react/src/components/MeetingResult.tsx)):

- Summary string from runtime
- Action items list (task + optional owner/due)
- Decisions list (text + optional made_by)
- Follow-ups string list
- Trace / report may be shown when the tool returns it — never synthesize business rows

## Failure

If `validate_entrypoint` or `execute_entrypoint` fails, surface the tool error envelope. Do **not** invent action items, decisions, follow-ups, or a summary.

## Optional client snippets

### Cursor

After [`../../clients/cursor/mcp.json.example`](../../clients/cursor/mcp.json.example) is installed:

1. Apply system-boundary rules.
2. Paste the agent checklist above.
3. Ask: “Run meeting-notes.process on this transcript via MCP tools and show only runtime fields.”

### Claude Desktop / Claude Code

Same checklist after installing [`../../clients/claude-desktop/mcp.json.example`](../../clients/claude-desktop/mcp.json.example) or [`../../clients/claude-code/.mcp.json.example`](../../clients/claude-code/.mcp.json.example). Claude must call MCP tools — do not paste a skill that invents meeting notes.

### ChatGPT / Grok

Until dedicated adapters ship (`llm-mcp-chatgpt-adapter` / `llm-mcp-grok-adapter`), map Actions / tool-calling schemas 1:1 to the tool sequence table above. The model still must not invent structured fields.

## Related tickets

| Ticket ID | Role |
|---|---|
| `llm-mcp-reference-apps-plan` | Scaffold + plan (Done) |
| `llm-mcp-meeting-notes-workflow` | This runbook |
| `llm-mcp-claude-live-smoke` / `llm-mcp-cursor-live-smoke` | Live evidence against traverse-starter (and optionally this workflow) |
