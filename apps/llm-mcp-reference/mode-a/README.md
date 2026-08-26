# Mode A — Spec 119 verified public-registry MCP host (scaffold)

LLM façade path that must use the **same public registry capabilities** as OS shells (`registry_ref` / published WASM), not the expedition demo catalog.

OS product shells stay **embedded**. This tree is Claude/Cursor-style MCP only.

| Layer | Status |
|---|---|
| Spec 119 (`119-verified-registry-mcp-mode-a`) | **Approved** (Traverse PR #1146) |
| Mode A `traverse-mcp` host (public-only discovery, inline `RuntimeRequest`, digest-verified WASM, versioned binary) | **Not shipped** — implement still missing after umbrella #865 closed |
| This tree | **Scaffold** — docs + fail-closed launcher + example MCP config |

Today’s `cargo run -p traverse-mcp -- stdio` path under `clients/` is the **expedition bootstrap**. Do not label it Spec 119 kit catalog.

## Contract (prepare → verified state → serve)

```text
LLM client  --MCP stdio-->  mode-a/serve.sh  -->  Traverse Mode A host (when shipped)
                                  ^
                                  |
                     host-supplied digest-verified public registry state
                                  ^
                                  |
                     mode-a/prepare.sh  (index sync + Spec 119 prepare docs)
```

Consumer rules (Spec 119):

1. **FR-001** — Discover only public capability/workflow entries from host-supplied verified state. No expedition bundle, private overrides, or network fallback at execute time.
2. **FR-002** — `validate` / `execute` / `render` accept inline `RuntimeRequest` JSON; `request_path` is mutually exclusive compatibility only.
3. **FR-003** — Missing or unverified state fails closed (not an empty catalog, not a demo fallback).
4. **FR-004** — Production execute uses the digest-verified published WASM artifact, not the expedition Rust executor.
5. **FR-005** — Responses are runtime-owned results + redacted evidence only. No invented title/tags.
6. **FR-006** — Prefer a versioned `traverse-mcp` binary with checksums; source-run is contributor-only.
7. **FR-007** — First release has **no kit content groups**. Discovery is public registry entries, not `traverse-starter` / `meeting-notes` group names.

## Env

| Variable | Meaning |
|---|---|
| `TRAVERSE_REPO` | Absolute path to Traverse checkout (contributor source-run) |
| `TRAVERSE_MCP_CACHE_ROOT` | Host-owned verified-state directory (you create/own it) |
| `TRAVERSE_WORKSPACE` | Registry workspace id (default `local-default`) |

## Prepare

```bash
export TRAVERSE_REPO="$(cd ../../../../Traverse && pwd)"   # adjust
export TRAVERSE_MCP_CACHE_ROOT="${HOME}/.cache/traverse-mcp-mode-a"
export TRAVERSE_WORKSPACE=local-default
bash prepare.sh
```

## Serve (fail-closed until upstream Mode A host)

```bash
bash serve.sh
```

Today `serve.sh` exits non-zero. Point LLM clients at expedition `clients/*/mcp.json.example` only if you accept that catalog. Point Spec 119 clients at [`mcp.json.example`](mcp.json.example) in this folder.

When Traverse ships Mode A flags, wire them here — do not invent a private CLI.

## Upstream

- Spec [`119-verified-registry-mcp-mode-a`](https://github.com/traverse-framework/Traverse/blob/main/specs/119-verified-registry-mcp-mode-a/spec.md)
- App-Refs catalog ticket `llm-mcp-traverse-starter-catalog` (Blocked until implement)
- Expedition bootstrap: [`../README.md`](../README.md)
