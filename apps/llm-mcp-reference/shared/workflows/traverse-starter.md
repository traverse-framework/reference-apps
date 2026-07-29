# Workflow runbook — traverse-starter

Equivalent to the **traverse-starter** OS shell: submit a short note; show runtime-owned metadata.

## Capability / workflow

Use the Traverse MCP server’s discovery/description tools to locate the starter note pipeline (validate → process → summarize or the published `traverse-starter.*` capabilities). Prefer executing the **governed workflow/entrypoint** the server exposes rather than free-form multi-step prompting.

## Happy path

1. Confirm MCP server is reachable (`describe_server` / discovery).
2. Execute with a note string input (example: `"Ship the MCP façade docs tomorrow"`).
3. Render **only** runtime fields from the execution report (e.g. title, tags, noteType, suggestedNextAction, status / validation issues / summary when present).

## Success looks like

Same as Web starter: structured fields filled by the runtime, not by the model.

## Failure

If execution fails, show the tool error. Do not invent a title/tags payload.
