# Cursor MCP Mode A evidence (`llm-mcp-traverse-starter-catalog`)

Captured **2026-09-07** against Traverse **main** (post [#1252](https://github.com/traverse-framework/Traverse/pull/1252) Spec 119 Mode A; after tagged `v0.10.0`).

## What was proven

Mode A host path via `TRAVERSE_MCP_REGISTRY_CACHE` pointing at the Traverse committed verified kit fixture (`crates/traverse-mcp/tests/fixtures/mode-a-cache`), equivalent to:

```bash
export TRAVERSE_REPO=/absolute/path/to/Traverse
export TRAVERSE_MCP_REGISTRY_CACHE="$TRAVERSE_REPO/crates/traverse-mcp/tests/fixtures/mode-a-cache"
# or: bash apps/llm-mcp-reference/mode-a/prepare.sh && bash apps/llm-mcp-reference/mode-a/serve.sh
printf '%s\n' … | TRAVERSE_MCP_REGISTRY_CACHE=… cargo run -q -p traverse-mcp -- stdio
```

### transcript A — discovery

File: [`cursor-mcp-stdio-transcript.jsonl`](cursor-mcp-stdio-transcript.jsonl)

Commands: `describe_server` → `list_entrypoints` → `list_content_groups` → `shutdown`

Observed: `"mode":"verified_public"`, governing spec `119-verified-registry-mcp-mode-a`, discovery source `host_verified_public_registry`, capability id `core.normalize-participants` (Loop WF1 kit used by App-Refs). Content groups empty (FR-007). No expedition catalog.

### transcript B — execute / render

File: [`cursor-mcp-execute-transcript.jsonl`](cursor-mcp-execute-transcript.jsonl)

Commands: `describe_server` → `list_entrypoints` → inline `execute_entrypoint` → inline `render_execution_report` → `shutdown` against `core.normalize-participants` @ `1.1.0`.

Observed: `"status":"completed"`, `"request_source":"inline"`, `"digest_matches_public_state":true`, artifact digest `sha256:6bb5c6300710de6090c4b5f25d611a6a6af7d2dd9e1bacb3bdb01b166110b5ad`.

### Fail closed

Empty `TRAVERSE_MCP_REGISTRY_CACHE` → startup failure with `"code":"registry_sync_missing"` and empty stdout (no expedition fallback).

## Runtime fields only

Execution/report envelopes come from Traverse MCP — this façade does **not** invent structured business fields.

## Catalog note

Mode A discovery is the host-prepared verified public metadata generation. The committed fixture seeds `core.normalize-participants`. Additional App-Refs pins (`meeting-notes.process`, `traverse-starter.process`) appear when the host prepares those digests into the same `HostRegistryCache` (library prepare APIs) — not via expedition fallback or App-Refs materialize rewrite.

## Reproduce

```bash
export TRAVERSE_REPO=/absolute/path/to/Traverse   # main with Mode A
export TRAVERSE_MCP_REGISTRY_CACHE="${HOME}/.cache/traverse-mcp-mode-a"
cd /absolute/path/to/App-References/apps/llm-mcp-reference/mode-a
bash prepare.sh
bash serve.sh   # or pipe JSONL commands into serve.sh
```

Upstream smoke: `bash "$TRAVERSE_REPO/scripts/ci/mcp_stdio_server_mode_a_smoke.sh"`.
