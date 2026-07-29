# Workflow runbook — meeting-notes

Equivalent to the **meeting-notes** OS shell: paste a transcript; show runtime-owned action items, decisions, follow-ups, summary.

## Capability

Discover and execute `meeting-notes.process` (or the workflow entrypoint that wraps it) via MCP.

## Happy path

1. Provide a short transcript as tool input.
2. Display only runtime list/structured fields from the result.
3. Do not invent action items the runtime did not return.

## Note

Full live wiring may land in ticket `llm-mcp-meeting-notes-workflow`. Until then this runbook is the contract for façades.
