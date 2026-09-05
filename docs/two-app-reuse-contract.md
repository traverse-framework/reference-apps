# Two-app reuse contract

**Ticket:** `two-app-reuse-contract` ([#281](https://github.com/traverse-framework/reference-apps/issues/281))  
**Upstream:** Traverse [#1168](https://github.com/traverse-framework/Traverse/issues/1168)  
**Governing:** ADR [`0006`](adr/0006-two-app-reuse-contract.md), [`production-packaging.md`](production-packaging.md) (`registry_ref`), [`runtime-bundle-sync.md`](runtime-bundle-sync.md)  
**Inventory date:** 2026-09-05  
**Source:** public `traverse-framework/registry` contract + GitHub Releases artifact (resolved independently for each consumer)

This record chooses one published capability and two independent App-References applications that **must** consume that exact immutable release. It does **not** claim execution evidence — that is `#282` (`two-app-reuse-execute`).

## Decision

| Field | Value |
|---|---|
| Capability id | `meeting-notes.process` |
| Namespace | `meeting-notes` |
| Immutable release (semver) | `1.3.2` |
| Contract schema version | `1.0.0` |
| Lifecycle | `active` |
| Artifact digest | `sha256:ec192a0c2104b08bee76418c5c6d44358036568d655d8465e506858d1aaadbf2` |
| Artifact URL | [meeting-process-agent.wasm](https://github.com/traverse-framework/registry/releases/download/artifacts/meeting-notes.process-1.1.0/meeting-process-agent.wasm) |
| Contract URL | [1.3.2/contract.json](https://github.com/traverse-framework/registry/blob/main/capabilities/meeting-notes/meeting-notes.process/1.3.2/contract.json) |

**Pinning rule (both apps):** exact version, no floating range. A `^1.0.0` or `^1.3.0` range is **not** allowed for this proof — those ranges can select different published artifacts (1.0.0 digest `sha256:5647c39a…` vs 1.3.2 digest `sha256:ec192a0c…`).

```json
{
  "capability_id": "meeting-notes.process",
  "capability_version": "1.3.2",
  "registry_ref": {
    "namespace": "meeting-notes",
    "id": "meeting-notes.process",
    "version_range": "1.3.2"
  }
}
```

App-manifest component `digest` for this capability must be the artifact digest above.

## Why these two apps

| App | Manifest boundary | User-facing purpose |
|---|---|---|
| `meeting-notes` | [`manifests/meeting-notes/app.manifest.json`](../manifests/meeting-notes/app.manifest.json) (`app_id`: `meeting-notes`) | Standalone meeting-notes shell: submit a transcript, render `action_items` / `decisions` / `follow_ups` / `summary` |
| `loop` | [`manifests/loop/app.manifest.json`](../manifests/loop/app.manifest.json) (`app_id`: `loop`) | Distinct WF1 product: ingest → extract → normalize → authorize (human review is UI-only) |

`meeting-notes.process` is the WF1 **ingest** step in Loop (`docs/loop-registry-deps.md`) and the sole capability in meeting-notes. Semantics fit both workflows: both take a transcript and need structured meeting-note fields. Loop then chains `core.extract-action-items`, `core.normalize-participants`, and `core.authorize` — those are Loop-only and are **not** the shared pin.

Rejected alternatives:

- `traverse-starter.process` — kit-only; no second independent product workflow consumes it.
- `core.extract-action-items` — published and Loop-pinned, but meeting-notes has no extract step and would invent a second workflow.

## No local substitute

Neither application may copy capability business logic or ship a private/local WASM in place of this release.

- Checked-in source components use `registry_ref` only (no `contract_path` / `wasm_*` on `manifests/`).
- App-References does not author `meeting-notes.process` WASM. Source of the binary is the public registry artifact above.
- Unit-test embedder doubles remain test-only and must not become the demo path.

## Registry / host route (supported path)

Intended production resolve (specs 054 / 055), **identical for both apps**:

1. **Publish** — capability already lives in `traverse-framework/registry` (`capabilities/meeting-notes/meeting-notes.process/1.3.2/`).
2. **Sync / prepare** — `traverse-cli registry sync` so the local public tier contains the record (spec 055). No live network fallback at resolve time (spec 054 FR-010).
3. **Verified cache** — fetch the artifact, digest-verify `sha256:ec192a0c…`, store content-addressed (spec 054 FR-011).
4. **Registration / adopt** — each app registers from its own `manifests/<app>/app.manifest.json`; the shared component resolves `registry_ref` `{namespace, id, version_range: "1.3.2"}` against the synced public tier.
5. **Execution host** — in-process public embedder (no required `traverse-cli serve`):

| App | Sync wrappers | Embedded hosts |
|---|---|---|
| meeting-notes | `scripts/ci/sync_{web,android,swift,winui}_meeting_notes_bundle.sh` | `apps/meeting-notes/{web-react,ios-swift,macos-swift,android-compose,windows-winui,linux-gtk,cli-rust}` |
| loop | `scripts/ci/sync_{web,android,swift,winui}_loop_bundle.sh` | `apps/loop/{web-react,ios-swift,macos-swift,android-compose,windows-winui,linux-gtk,cli-rust}` |

Host pin (`runtime/runtime.wasm`) is orthogonal — follow [`runtime-bundle-sync.md`](runtime-bundle-sync.md).

### Interim materialize (not a second capability)

Platform sync may still rewrite destination bundles from `$TRAVERSE_REPO` example paths (`scripts/ci/sync_bundle_core.sh` `KNOWN` map for `("meeting-notes", "meeting-notes.process")`). That is a packaging workaround (`retire-registry-ref-materialize-hosts`, Future — BundleEmbedder + Spec 107). It is **not** permission to treat the Traverse example tree as a different capability. Execution evidence (`#282`) must assert the published digest above after prepare, and fail if a consumer runs a different artifact.

## Current drift (this ticket does not change manifests)

| Consumer | Today | Required by this contract |
|---|---|---|
| Loop component | `capability_version` `1.3.2`, `version_range` `^1.3.0`, app digest `sha256:ec192a0c…` | Exact `1.3.2` + same digest (tighten range only) |
| meeting-notes component | `capability_version` `1.0.0`, `version_range` `^1.0.0`, app digest `sha256:5647c39a…` (registry **1.0.0** artifact) | Realign to `1.3.2` + `sha256:ec192a0c…` |

I/O schema is compatible (`transcript` in; `action_items` / `decisions` / `follow_ups` / `summary` out). Meeting-notes UI does not need new business fields to consume 1.3.2.

`1.0.1` is a fixed-output fixture (does not read the transcript). Do not use it for this proof.

## Downstream

| Ticket | Role |
|---|---|
| `#282` `two-app-reuse-execute` | Align meeting-notes pin; execute both apps; publish digest-equal evidence |
| `#283` `two-app-reuse-lifecycle` | Compatible upgrade + deprecation outcomes for the same pair |

## Re-verification

Resolve the **same** public contract once per consumer workspace and compare all four values. They must match.

```bash
python3 - <<'PY'
import hashlib, json, urllib.request

CONTRACT = (
    "https://raw.githubusercontent.com/traverse-framework/registry/main/"
    "capabilities/meeting-notes/meeting-notes.process/1.3.2/contract.json"
)
expected = {
    "id": "meeting-notes.process",
    "version": "1.3.2",
    "schema_version": "1.0.0",
    "digest": "sha256:ec192a0c2104b08bee76418c5c6d44358036568d655d8465e506858d1aaadbf2",
}

def resolve(consumer: str) -> dict:
    with urllib.request.urlopen(CONTRACT) as response:
        contract = json.loads(response.read().decode())
    art = contract.get("artifact") or {}
    rec = {
        "consumer": consumer,
        "id": contract.get("id"),
        "version": contract.get("version"),
        "schema_version": contract.get("schema_version"),
        "digest": art.get("digest"),
        "url": art.get("url"),
    }
    print(rec)
    return rec

a = resolve("meeting-notes")
b = resolve("loop")
for key in ("id", "version", "schema_version", "digest"):
    assert a[key] == b[key] == expected[key], (key, a[key], b[key])

req = urllib.request.Request(a["url"], headers={"User-Agent": "app-refs-two-app-reuse"})
with urllib.request.urlopen(req) as response:
    digest = "sha256:" + hashlib.sha256(response.read()).hexdigest()
assert digest == expected["digest"], digest
print("OK four-value pin + wasm digest")
PY
```

Local boundary check (no network):

```bash
bash scripts/ci/two_app_reuse_contract_check.sh
```
