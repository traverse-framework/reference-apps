# Mode A — Spec 119 verified public-registry MCP host

LLM façade path that uses the **same public registry capabilities** as OS shells (`registry_ref` / published WASM), not the expedition demo catalog.

OS product shells stay **embedded**. This tree is Claude/Cursor-style MCP only.

| Layer | Status |
|---|---|
| Spec 119 (`119-verified-registry-mcp-mode-a`) | **Approved** |
| Mode A `traverse-mcp` host | **Shipped on Traverse main** via [#1241](https://github.com/traverse-framework/Traverse/issues/1241) / [#1252](https://github.com/traverse-framework/Traverse/pull/1252) (post-`v0.10.0`; pin a checkout that includes that merge, or the next release once tagged) |
| This tree | **Live consumer** — prepare → serve → Cursor/Claude evidence under `evidence/` and `clients/*/evidence/` |

Bare `cargo run -p traverse-mcp -- stdio` **without** `TRAVERSE_MCP_REGISTRY_CACHE` is still the **expedition bootstrap**. Do not label it Spec 119.

## Contract (prepare → verified state → serve)

```text
LLM client  --MCP stdio-->  mode-a/serve.sh  -->  traverse-mcp stdio (Mode A)
                                  ^
                                  |
                     TRAVERSE_MCP_REGISTRY_CACHE (digest-verified public state)
                                  ^
                                  |
                     mode-a/prepare.sh  (seeds HostRegistryCache; optional registry sync)
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
| `TRAVERSE_REPO` | Absolute path to Traverse checkout (contributor source-run; must include Mode A) |
| `TRAVERSE_MCP_REGISTRY_CACHE` | Host-owned verified-state directory (canonical Spec 119 name) |
| `TRAVERSE_MCP_CACHE_ROOT` | App-Refs alias for `TRAVERSE_MCP_REGISTRY_CACHE` |
| `TRAVERSE_WORKSPACE` | Registry workspace id (default `local-default`) |
| `TRAVERSE_MCP_PREPARE_SYNC` | Set `1` during prepare to also run `registry sync` |

## Prepare

```bash
export TRAVERSE_REPO="$(cd ../../../../Traverse && pwd)"   # adjust
export TRAVERSE_MCP_REGISTRY_CACHE="${HOME}/.cache/traverse-mcp-mode-a"
export TRAVERSE_WORKSPACE=local-default
bash prepare.sh
```

`prepare.sh` seeds the Traverse committed Mode A fixture (includes
`core.normalize-participants` @ 1.1.0 — a Loop WF1 dependency used by App-Refs).
Hosts may extend the same cache shape with additional published `registry_ref`s
via `traverse_embedder::prepare_registry_dependency` + `publish_public_metadata`
(no App-Refs materialize rewrite).

## Serve

```bash
bash serve.sh
```

Point Spec 119 clients at [`mcp.json.example`](mcp.json.example).

## Evidence

Live Mode A transcripts (verified_public, inline execute, digest match):

- [`evidence/mode-a-stdio-transcript.jsonl`](evidence/mode-a-stdio-transcript.jsonl)
- [`evidence/mode-a-execute-transcript.jsonl`](evidence/mode-a-execute-transcript.jsonl)
- Mirrored under `clients/cursor|claude-desktop|claude-code/evidence/`

## Upstream

- Spec [`119-verified-registry-mcp-mode-a`](https://github.com/traverse-framework/Traverse/blob/main/specs/119-verified-registry-mcp-mode-a/spec.md)
- Docs: [mcp-stdio-server.md](https://github.com/traverse-framework/Traverse/blob/main/docs/mcp-stdio-server.md), [mcp-mode-a-release-evidence.md](https://github.com/traverse-framework/Traverse/blob/main/docs/mcp-mode-a-release-evidence.md)
- App-Refs ticket `llm-mcp-traverse-starter-catalog`
