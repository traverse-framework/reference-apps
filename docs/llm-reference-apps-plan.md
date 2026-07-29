# LLM reference façades (MCP) — plan

## Purpose

Extend App-References beyond OS UI shells with **reference façades for major LLM products** (Claude, ChatGPT, Grok, Cursor, and similar).

These façades are the LLM equivalent of `traverse-starter` / `meeting-notes` clients:

| OS ref app | LLM ref façade |
|---|---|
| Swift / React / WinUI shell | Claude Desktop / Cursor / ChatGPT / Grok client config |
| Submits input → renders runtime fields | Invokes MCP tools → presents runtime JSON (no invented business fields) |
| Embedded WASM host | Traverse **MCP stdio server** (`traverse-mcp`) over the same capabilities/workflows |

**Core thesis:** prefer Traverse **workflows/capabilities** over traditional prompt “skills” for business logic. The model handles language and intent; **deterministic logic runs in Traverse** (local embed or a host you control) → more repeatable outcomes and **lower token cost**.

## Architecture boundary (locked)

```text
┌─────────────────────────────┐
│  LLM product (Claude/…)     │  language, tool selection, UX
└──────────────┬──────────────┘
               │ MCP (stdio / product adapter)
┌──────────────▼──────────────┐
│  apps/llm-mcp-reference/    │  App-Refs façade (configs, prompts, docs)
│  — no business field math — │
└──────────────┬──────────────┘
               │ tools: discover / execute / report
┌──────────────▼──────────────┐
│  Traverse traverse-mcp      │  façade over runtime authority
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│  Registry capabilities +    │  WASM agents + workflows (SoT)
│  workflows (e.g. starter)   │
└─────────────────────────────┘
```

Rules (same as OS shells):

1. **No business logic in the façade** — do not compute title/tags/recommendations in prompts or client code.
2. **Public Traverse surfaces only** — MCP package + public docs; no private runtime crates.
3. **Same catalog as OS apps** — `registry_ref` / published capabilities (e.g. `traverse-starter.*`, `meeting-notes.process`).
4. **Secondary tier** — not merge-blocking `embedded_smoke`; lighter smoke proves scaffold integrity.

## Why not “skills”?

| Traditional skill | Traverse workflow via MCP |
|---|---|
| Behavior re-negotiated in tokens each turn | Contract + WASM + workflow are versioned and tested |
| Drift across models/vendors | Same capability digest for Claude, Cursor, ChatGPT adapters |
| High token use for process control | Model supplies input; runtime returns structured fields |
| Hard to CI | Capability validation + MCP smoke already exist upstream |

Skills remain useful for **authoring guidance** (e.g. [claude-skills](https://github.com/traverse-framework/claude-skills) for contract writing). They are **not** the place to implement product business rules that OS shells already get from WASM.

## Reference clients in this repo

Canonical tree: [`apps/llm-mcp-reference/`](../apps/llm-mcp-reference/).

| Client folder | Product shape | v1 deliverable |
|---|---|---|
| `clients/claude-desktop/` | Claude Desktop MCP config | `mcp.json.example` + README |
| `clients/claude-code/` | Claude Code / CLI MCP | `.mcp.json.example` + README |
| `clients/cursor/` | Cursor MCP | `mcp.json.example` + README |
| `clients/chatgpt/` | ChatGPT (Custom GPT / Actions; MCP where available) | Adapter notes + tool mapping |
| `clients/grok/` | Grok / xAI tool calling | Adapter notes + tool mapping |

Shared:

- `shared/prompts/system-boundary.md` — mandatory “runtime owns fields” instruction
- `shared/workflows/*.md` — which starter workflows to call and what success looks like

## Runtime host modes

| Mode | When | Notes |
|---|---|---|
| **A. MCP stdio → local Traverse** (v1 default) | Developer laptop / agent IDE | `cargo run -p traverse-mcp -- stdio` with `TRAVERSE_REPO` |
| **B. MCP → embedded host in a sidecar process** | Stronger product isolation | Future; align with Spec 520 prepare/cache |
| **C. Remote MCP gateway** | Multi-tenant SaaS | Future; needs auth/tenancy — not this slice |

v1 documents **Mode A** only. Do not revive HTTP `traverse-cli serve` as the production architecture for primary OS shells; MCP stdio is a **separate agent façade**, not a replacement for embedded Web/iOS/Android clients.

## Phased tickets (Project 2)

| Ticket ID | Intent | Status intent |
|---|---|---|
| `llm-mcp-reference-apps-plan` | Plan + scaffold (this doc + tree) | Done (#238) |
| `llm-mcp-claude-live-smoke` | Live Claude Desktop/Code path against `traverse-starter` | Done (#241) |
| `llm-mcp-cursor-live-smoke` | Live Cursor MCP path | Done (#240) |
| `llm-mcp-meeting-notes-workflow` | Document + config for meeting-notes via MCP | Done (#239) |
| `llm-mcp-chatgpt-adapter` | ChatGPT Actions/GPT mapping (or MCP when shipped) | Future / Ready when API stable |
| `llm-mcp-grok-adapter` | Grok tool-calling mapping | Future / Ready when API stable |
| `llm-mcp-traverse-starter-catalog` | Expose kit (`traverse-starter.*` / meeting-notes) on MCP stdio catalog | Blocked — Traverse [#865](https://github.com/traverse-framework/Traverse/issues/865) / registry [#99](https://github.com/traverse-framework/registry/issues/99) |
| `llm-mcp-embedded-host` | Mode B embedded prepare/cache for MCP host | Blocked on Traverse Spec 520 implement |

## Success criteria (plan slice)

- A new contributor can open `apps/llm-mcp-reference/README.md` and understand LLM façades vs OS shells.
- Example MCP configs point at `traverse-mcp` stdio without inventing business logic.
- Board/docs list LLM façades as an explicit secondary tier.

## Non-goals

- Replacing primary OS product shells
- Prompt-only implementations of starter/doc-approval/meeting-notes pipelines
- Shipping store listings for ChatGPT plugins in this slice
- Multi-tenant hosted MCP SaaS

## Related

- Traverse MCP stdio: https://github.com/traverse-framework/Traverse/blob/main/docs/mcp-stdio-server.md  
- youaskm3 MCP client path: https://github.com/traverse-framework/Traverse/blob/main/docs/youaskm3-canonical-mcp-client-path.md  
- OS getting started: [`getting-started-embedded.md`](getting-started-embedded.md)  
- Production plan: [`production-reference-plan.md`](production-reference-plan.md)  
