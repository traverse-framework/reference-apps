# LLM MCP reference façades

Secondary App-References tier: **LLM product façades** that call Traverse **workflows/capabilities** through MCP instead of encoding business logic in prompt “skills”.

Shared prompts/workflows follow Specs 001/002 presentation vocabulary (`idle|loading|loaded|blocked|ended|error`) and still forbid inventing business fields — see [`shared/prompts/system-boundary.md`](shared/prompts/system-boundary.md).

Plan: [`docs/llm-reference-apps-plan.md`](../../docs/llm-reference-apps-plan.md)

## Layout

```text
apps/llm-mcp-reference/
  README.md                 ← this file
  mode-a/                   ← Spec 119 public-registry MCP scaffold (fail-closed serve)
  mode-b/                   ← Spec 520 prepare/cache scaffold (fail-closed serve)
  shared/
    prompts/system-boundary.md
    workflows/traverse-starter.md
    workflows/meeting-notes.md
  clients/
    claude-desktop/
    claude-code/
    cursor/
    chatgpt/
    grok/
```

## Quick start (Spec 119 Mode A — preferred)

```bash
export TRAVERSE_REPO="$(cd ../Traverse && pwd)"   # main with Mode A (#1252+), or next release
export TRAVERSE_MCP_REGISTRY_CACHE="${HOME}/.cache/traverse-mcp-mode-a"
cd apps/llm-mcp-reference/mode-a
bash prepare.sh
bash serve.sh
```

Point `clients/<product>/` at [`mode-a/mcp.json.example`](mode-a/mcp.json.example), paste `shared/prompts/system-boundary.md`, and follow the workflow runbooks. Display **only** runtime fields.

Bare `cargo run -p traverse-mcp -- stdio` **without** `TRAVERSE_MCP_REGISTRY_CACHE` is still **expedition bootstrap** — not Spec 119.

## Mode A (Spec 119 public registry)

Registry-MCP path for the same capabilities OS shells load via `registry_ref`. OS apps stay embedded; this is Claude/Cursor MCP only.

See [`mode-a/README.md`](mode-a/README.md), [`mode-a/mcp.json.example`](mode-a/mcp.json.example), [`mode-a/prepare.sh`](mode-a/prepare.sh), and [`mode-a/serve.sh`](mode-a/serve.sh).

**Honest status:** Spec 119 Mode A host shipped on Traverse **main** ([#1241](https://github.com/traverse-framework/Traverse/issues/1241) / [#1252](https://github.com/traverse-framework/Traverse/pull/1252)). Tagged **v0.10.0** binaries remain expedition-only — use a post-#1252 checkout (or the next release) for Mode A. Live evidence uses verified-public discovery + inline `RuntimeRequest` + digest-verified WASM (no expedition fallback; no kit content groups in v1 per FR-007). Seeded proof kit: `core.normalize-participants` (Loop WF1).

## Mode B (scaffold — Spec 520 prepare / verified cache)

Stronger isolation path: prepare registry deps into a **host-owned verified cache**, then serve MCP from that cache — **no App-Refs materialize rewrite**.

See [`mode-b/README.md`](mode-b/README.md), [`mode-b/mcp.json.example`](mode-b/mcp.json.example), and fail-closed [`mode-b/serve.sh`](mode-b/serve.sh).

**Honest status:** Spec 520 library APIs shipped in Traverse (#860). The Mode B MCP host CLI is **not** shipped (Traverse Project 1 ticket-id `implement-mode-b-embedded-mcp-host`, issue [#1242](https://github.com/traverse-framework/Traverse/issues/1242)). App-Refs ticket `llm-mcp-embedded-host` is **Future**. Mode A is the runnable Spec 119 LLM path; Mode B launcher exits non-zero until that host exists.

Optional bearer token (execution commands):

```bash
TRAVERSE_MCP_STDIO_BEARER_TOKEN="local-dev-secret" \
  cargo run -p traverse-mcp -- stdio
```

## Boundary

| Allowed in this tree | Forbidden |
|---|---|
| MCP configs, adapter notes, workflow runbooks | Computing title/tags/recommendations in prompts |
| Rendering/summarizing **runtime JSON** for humans | Private Traverse crate imports |
| Linking to registry/`registry_ref` capabilities | Treating HTTP `serve` as the OS-shell production path |

## Validation

```bash
bash scripts/ci/llm_mcp_reference_smoke.sh
```

## Upstream docs

- [MCP stdio server](https://github.com/traverse-framework/Traverse/blob/main/docs/mcp-stdio-server.md)
- [Packaged MCP artifact](https://github.com/traverse-framework/Traverse/blob/main/docs/packaged-traverse-mcp-server-artifact.md)
- [youaskm3 canonical MCP client path](https://github.com/traverse-framework/Traverse/blob/main/docs/youaskm3-canonical-mcp-client-path.md)
