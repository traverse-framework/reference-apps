# Production packaging

How App-References packages primary shells for embed: digest-pinned runtime sync, app manifests, and (later) public `registry_ref` capability resolution.

## Digest-pinned runtime + manifests

See [`runtime-bundle-sync.md`](runtime-bundle-sync.md) for the shared sync core and per-platform wrappers. Release-evidence playbook expansion is tracked in [#175](https://github.com/traverse-framework/reference-apps/issues/175).

## `registry_ref` consumer contract

Docs-only contract for how primary App-References shells will consume public registry capabilities via `registry_ref` (**implementation is [#97](https://github.com/traverse-framework/reference-apps/issues/97) — Future / gated**).

Governing Traverse specs:

- [`054-public-scope-registry-ref`](https://github.com/traverse-framework/Traverse/blob/main/specs/054-public-scope-registry-ref/spec.md)
- [`055-registry-sync`](https://github.com/traverse-framework/Traverse/blob/main/specs/055-registry-sync/spec.md)

## Status

| Layer | Today | After #97 |
|---|---|---|
| Component manifests under `manifests/` | **Local-path** (`contract_path` + `wasm_binary_path` + `wasm_digest`) | Selected components may use `registry_ref` instead |
| Sync / packaging | [`runtime-bundle-sync.md`](runtime-bundle-sync.md) copies local example trees | Still sync app manifests; capability artifacts come from registry sync + digest-verified cache |
| Implementation ticket | [#97](https://github.com/traverse-framework/reference-apps/issues/97) remains **Future** until registry seed + Traverse gates clear | Flip Ready only when upstream publish/sync works |

**Do not switch any checked-in manifest to `registry_ref` in this ticket or any PR that only lands this doc.** Premature switches break Phase 3 embedded smoke until registry seed-publish and `traverse-cli registry sync` are available.

## Intended component shape

Exactly one capability source per component (spec 054 FR-007):

**Local (current — keep until #97):**

```json
{
  "component_id": "traverse-starter.process-component",
  "capability_id": "traverse-starter.process",
  "contract_path": "../../_traverse/contracts/examples/traverse-starter/capabilities/process/contract.json",
  "wasm_binary_path": "../../_traverse/examples/traverse-starter/process-agent/artifacts/process-agent.wasm",
  "wasm_digest": "sha256:…"
}
```

**Registry (target for `traverse-starter.process` in #97):**

```json
{
  "component_id": "traverse-starter.process-component",
  "capability_id": "traverse-starter.process",
  "registry_ref": {
    "namespace": "traverse-starter",
    "id": "traverse-starter.process",
    "version_range": "^1.0.0"
  }
}
```

`registry_ref` fields (spec 054 FR-008): non-empty `namespace`, `id`, and `version_range`. Do **not** also declare local `contract_path` / `wasm_*` on the same component.

## Resolve / sync flow (intended)

1. Publisher lands capability in the public registry (Traverse registry PR / seed flow — outside this repo).
2. Consumer runs `traverse-cli registry sync` so the **local public tier** contains the record (spec 055).
3. App registration / embed host resolves `registry_ref` **only** against that synced public tier — no live network fallback (spec 054 FR-010).
4. At registration time, artifacts are fetched, **digest-verified**, and stored in a local content-addressed cache (spec 054 FR-011).
5. Runtime execution reads only local durable state + cached artifacts.

If sync has not run, registration must fail with a stable error that `traverse-cli registry sync` is required (spec 054 scenario 2).

## Digests vs registry

| Concern | Local-path today | `registry_ref` later |
|---|---|---|
| WASM integrity | `wasm_digest` on the component manifest | Published digest from the registry record; verified at fetch |
| Runtime host pin | `$TRAVERSE_REPO/runtime/runtime-release.json` via sync wrappers | Unchanged — host pin is orthogonal to capability `registry_ref` |
| App identity | `manifests/<app>/app.manifest.json` component digests | App manifest still lists components; capability bytes may come from cache |

## What stays local-path until #97

- All of `manifests/traverse-starter/components/*` and `manifests/doc-approval/components/*`
- Web `FetchBundleLoader` trees populated by `sync_web_*_bundle.sh` (example WASM under `_traverse/`)
- Native digest-pinned `runtime/runtime.wasm` sync ([`runtime-bundle-sync.md`](runtime-bundle-sync.md))

First intended cutover: **`traverse-starter.process` only** (#97). Other components stay local until their registry publish gates exist.

## Agent / playbook rules

- Packaging and production playbooks may **describe** this contract; they must not instruct agents to rewrite manifests to `registry_ref` yet.
- [#97](https://github.com/traverse-framework/reference-apps/issues/97) owns the code/manifest switch and remains Future until Traverse registry seed + sync CLI gates are met.
- UI remains a rendering layer — registry adoption does not move business field computation into App-References.

## Related

- Plan: [`production-reference-plan.md`](production-reference-plan.md)
- Sync: [`runtime-bundle-sync.md`](runtime-bundle-sync.md)
- Playbook: [`production-playbook.md`](production-playbook.md)
