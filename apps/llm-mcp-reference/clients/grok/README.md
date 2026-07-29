# Grok — Traverse workflow façade

Grok / xAI tool-calling should bind to Traverse capabilities the same way OS shells do: **tools execute workflows; the model does not invent structured business fields**.

## v1 approach

1. Prefer MCP if/when the client supports stdio or remote MCP compatible with `traverse-mcp`.
2. Otherwise document tool schemas that forward to a thin gateway over Traverse public APIs (same boundary as ChatGPT Actions).
3. System prompt: [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md).
4. Workflow: [`../../shared/workflows/traverse-starter.md`](../../shared/workflows/traverse-starter.md).

## Follow-on ticket

`llm-mcp-grok-adapter` — concrete tool schema + smoke once the integration path is chosen.
