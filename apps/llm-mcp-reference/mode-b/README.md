# Mode B — MCP → Spec 520 prepare / verified cache (scaffold)

Secondary façade for LLM clients that want **stronger isolation** than Mode A expedition stdio: prepare registry dependencies into a **host-owned verified cache**, then serve MCP from that cache (no App-Refs `materialize` rewrite).

| Layer | Status |
|---|---|
| Spec 520 library (`HostRegistryCache`, prepare / offline resolve) | Shipped in Traverse (#860) |
| Mode B MCP host process (`traverse-mcp` embedded / cache-root serve) | **Not shipped upstream** — see Traverse #865 |
| This tree | **Scaffold** — docs + fail-closed launcher + example MCP config |

Mode A (`cargo run -p traverse-mcp -- stdio`) remains the only **runnable** LLM path today.

## Contract (prepare → cache → serve)

```text
LLM client  --MCP stdio-->  mode-b/serve.sh  -->  Traverse Mode B host (when shipped)
                                  ^
                                  |
                     TRAVERSE_MCP_CACHE_ROOT (host-owned verified cache)
                                  ^
                                  |
                     mode-b/prepare-cache.sh  (index sync + Spec 520 prepare docs)
```

Rules:

1. **No business fields** in this façade — same as Mode A / OS shells.
2. **No App-Refs materialize** — leave `registry_ref` intact; do not rewrite destination manifests to local `wasm_*` paths here.
3. **Fail closed** — `serve.sh` must not silently fall back to Mode A expedition stdio (that would mislabel Mode B).

## Env

| Variable | Meaning |
|---|---|
| `TRAVERSE_REPO` | Absolute path to Traverse checkout |
| `TRAVERSE_MCP_CACHE_ROOT` | Host-owned cache directory (you create/own it) |
| `TRAVERSE_WORKSPACE` | Registry workspace id (default `local-default`) |
| `TRAVERSE_REGISTRY_TOKEN` | Optional token for private registry sync |

## Prepare (documented)

```bash
export TRAVERSE_REPO="$(cd ../../../../Traverse && pwd)"   # adjust
export TRAVERSE_MCP_CACHE_ROOT="${HOME}/.cache/traverse-mcp-mode-b"
export TRAVERSE_WORKSPACE=local-default
bash prepare-cache.sh
```

`prepare-cache.sh` runs public index sync via `traverse-cli` and prints the Spec 520 **library** prepare steps. There is no public one-liner CLI for artifact prepare yet — hosts call:

- Rust: `traverse_embedder::{HostRegistryCache, prepare_registry_dependency, resolve_registry_dependency_offline}`
- Web (reference): `prepareRegistryDependency` / `resolveRegistryDependencyOffline` from TraverseEmbedder

## Serve (fail-closed until upstream Mode B host)

```bash
bash serve.sh
```

Intended upstream shape (not available yet):

```bash
cargo run -p traverse-mcp -- embedded --cache-root "$TRAVERSE_MCP_CACHE_ROOT"
# or env-driven offline serve once Traverse ships it
```

Today `serve.sh` exits non-zero with a clear message. Point LLM clients at Mode A until Traverse lands the Mode B host (umbrella #865).

## MCP client example

See [`mcp.json.example`](mcp.json.example). Absolute paths required.

## Upstream

- Spec 520 / `080-embedded-registry-cache`
- Traverse issue [#865](https://github.com/traverse-framework/Traverse/issues/865) (Mode B host child)
- App-Refs Mode A: [`../README.md`](../README.md)
