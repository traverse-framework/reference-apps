# ChatGPT — Traverse workflow façade

ChatGPT’s integration surface evolves (Custom GPTs, Actions, MCP support where offered). This folder is the **App-Refs equivalent** of an OS client README: how to bind ChatGPT to Traverse **without** turning the GPT instructions into a business-logic skill.

## v1 approach

1. Run Traverse MCP stdio locally (or a future hosted MCP gateway — not specified here).
2. If the product supports MCP, point it at the same command shape as [`../claude-desktop/mcp.json.example`](../claude-desktop/mcp.json.example).
3. If only HTTP Actions are available, map Actions to a **thin gateway** that calls the same capabilities the MCP server would (gateway is Traverse/App ops — not invented field math in the GPT).
4. Always include [`../../shared/prompts/system-boundary.md`](../../shared/prompts/system-boundary.md) in GPT instructions.
5. Success criteria: same as [`../../shared/workflows/traverse-starter.md`](../../shared/workflows/traverse-starter.md).

## Non-goals (this slice)

- Publishing a store GPT
- Re-implementing validate/process/summarize in the GPT prompt

## Follow-on ticket

`llm-mcp-chatgpt-adapter` — concrete Actions schema or MCP wiring once the product API is stable for this kit.
