# Loop WF1 — registry dependency inventory

**Ticket:** `loop-wf1-registry-deps`  
**Governing:** Spec [`003-loop-wf1-reference-app`](specs/003-loop-wf1-reference-app/spec.md), ADR [`0003`](adr/0003-loop-wasm-from-registry-only.md)  
**Inventory date:** 2026-08-23  
**Source:** local clone of `traverse-framework/registry` (`capabilities/**/contract.json` artifact digests)

WF1 product sequence (Loop package v2): **ingest → extract → normalize → authorize** (human review is UI-only).

## Recommended pins for App-Refs Loop clients

| Role | Capability id | Version | Artifact digest | Release URL |
|---|---|---|---|---|
| Meeting ingest | `meeting-notes.process` | `1.3.2` | `sha256:ec192a0c2104b08bee76418c5c6d44358036568d655d8465e506858d1aaadbf2` | [wasm](https://github.com/traverse-framework/registry/releases/download/artifacts/meeting-notes.process-1.1.0/meeting-process-agent.wasm) |
| Extract action items | `core.extract-action-items` | `1.2.0` | `sha256:1f815c8debd26d9f17cc895e49154e204b05b637df6d66760c59002f1ef0a503` | [wasm](https://github.com/traverse-framework/registry/releases/download/artifacts/core.extract-action-items-1.2.0/core-extract-action-items.wasm) |
| Normalize participants | `core.normalize-participants` | `1.1.0` | `sha256:6bb5c6300710de6090c4b5f25d611a6a6af7d2dd9e1bacb3bdb01b166110b5ad` | [wasm](https://github.com/traverse-framework/registry/releases/download/artifacts/core.normalize-participants-1.1.0/core-normalize-participants.wasm) |
| Authorize | `core.authorize` | `1.2.0` | `sha256:0c318fff56a74eddfbc1ab850c25c1ba191744309984a07bd503b8cd9cb92e40` | [wasm](https://github.com/traverse-framework/registry/releases/download/artifacts/core.authorize-1.2.0/core-authorize.wasm) |

Notes:

- Digests were read from each version’s `contract.json` `artifact.digest` field.
- `meeting-notes.process` `1.1.0`–`1.3.2` currently share the same published artifact digest/URL (registry republish history). Prefer the newest **active** contract version (`1.3.2`) in manifests; re-verify digests before shipping if registry republishes.
- `core.extract-action-items` `1.1.0` is deprecated in-registry (honesty republish); prefer `1.2.0`.

## Also published (not required for WF1 slice)

The registry already contains many Loop package v2 capability ids (nudge / follow-up / escalation family) under `capabilities/core/` — e.g. `core.select-items-for-followup`, `core.generate-nudge-message`, `core.transition-action-status`. Those are **WF3+** and stay out of scope for Spec 003.

## Remaining gaps

| Item | Status | Impact on `loop-wf1-multi-os` |
|---|---|---|
| Capability WASM digests for WF1 four-step set | **Published** | Unblocked |
| Registry-hosted workflow id `loop.*` / `wf1` composition | **Not published** under `registry/workflows/` (only `traverse-starter`, `doc-approval`, examples today) | **Non-blocking** if Loop ships an in-app workflow JSON that `registry_ref`s the four capabilities (same pattern as other App-Refs manifests) |
| Dedicated “Loop” content group / MCP kit id | Not required by Spec 003 | Out of scope |

## Unblock decision

As of 2026-08-23, **capability digests required by Spec 003 FR path exist**.  
`loop-wf1-multi-os` may move to **Ready**. Loop implementation should:

1. Pin the four capabilities above via `registry_ref` + digest-synced bundles (follow `docs/runtime-bundle-sync.md` / existing sync scripts).
2. Compose WF1 in the Loop app manifest/workflow (App-Refs), not invent WASM.
3. Optionally file a **Future** Traverse/registry ticket for a first-party `workflows/loop/...` publish if we want the composition hosted upstream later.

## Re-verification

```bash
# From a registry checkout
python3 - <<'PY'
import json
from pathlib import Path
pins = [
  ("meeting-notes/meeting-notes.process", "1.3.2"),
  ("core/core.extract-action-items", "1.2.0"),
  ("core/core.normalize-participants", "1.1.0"),
  ("core/core.authorize", "1.2.0"),
]
for path, ver in pins:
    c = json.loads(Path(f"capabilities/{path}/{ver}/contract.json").read_text())
    art = c.get("artifact") or {}
    print(c.get("id"), ver, art.get("digest"), art.get("url"))
PY
```
