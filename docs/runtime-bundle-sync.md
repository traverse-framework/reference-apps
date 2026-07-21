# Runtime bundle sync contract

Single packaging contract for digest-pinned Traverse runtime artifacts and app manifests across App-References platforms (#174).

## Pin source

| Artifact | Path in Traverse checkout |
|---|---|
| Runtime WASM | `$TRAVERSE_REPO/runtime/runtime.wasm` |
| Release metadata | `$TRAVERSE_REPO/runtime/runtime-release.json` |

`runtime-release.json` must include `sha256` matching the WASM bytes. Sync scripts **verify** this after copy.

App + component manifests always come from this repo: `manifests/<app_id>/`.

## Shared core + thin wrappers

| Layer | Path |
|---|---|
| Shared rules | [`scripts/ci/sync_bundle_core.sh`](../scripts/ci/sync_bundle_core.sh) |
| Platform wrappers | `scripts/ci/sync_*_bundle.sh` (keep these names) |

Wrappers only choose destination, app id, component list, and which optional layers to include:

| Flag | Values | Used by |
|---|---|---|
| `--runtime` | `required` / `none` | Native embeds require; Web uses `none` (browser host, app WASM via examples) |
| `--traverse-assets` | `required` / `optional` / `none` | Web required; WinUI optional; Swift/Android none |
| `--manifest-layout` | `root` / `subdir` | Android uses `subdir` (`manifests/` under bundle); others `root` |

## Commands

```bash
export TRAVERSE_REPO=/path/to/Traverse

# Web (FetchBundleLoader — examples/workflows/contracts)
bash scripts/ci/sync_web_starter_bundle.sh
bash scripts/ci/sync_web_doc_approval_bundle.sh

# Android (runtime.wasm + manifests/)
bash scripts/ci/sync_android_starter_bundle.sh
bash scripts/ci/sync_android_doc_approval_bundle.sh

# Swift iOS + macOS (runtime.wasm + root manifests)
bash scripts/ci/sync_swift_starter_bundle.sh
bash scripts/ci/sync_swift_doc_approval_bundle.sh

# WinUI (runtime.wasm + root manifests + optional Traverse trees)
bash scripts/ci/sync_winui_starter_bundle.sh
bash scripts/ci/sync_winui_doc_approval_bundle.sh
```

After sync, assert the pin:

```bash
python3 - <<'PY'
import hashlib, json, pathlib
p = pathlib.Path("apps/traverse-starter/android-compose/app/src/main/assets/bundles/traverse-starter/runtime")
meta = json.loads((p / "runtime-release.json").read_text())
digest = hashlib.sha256((p / "runtime.wasm").read_bytes()).hexdigest()
assert meta["sha256"] == digest, (meta["sha256"], digest)
print("OK", meta["runtime_version"], digest)
PY
```

## Vendor SDK refresh (separate from runtime pin)

Public embedder SDKs live under `vendor/`. Refresh recipes:

- [`vendor/traverse-embedder-web/ORIGIN.md`](../vendor/traverse-embedder-web/ORIGIN.md)
- [`vendor/traverse-embedder-swift/ORIGIN.md`](../vendor/traverse-embedder-swift/ORIGIN.md)
- [`vendor/traverse-embedder-dotnet/ORIGIN.md`](../vendor/traverse-embedder-dotnet/ORIGIN.md)

After a Traverse runtime release bumps `runtime/runtime-release.json`, re-run the platform sync wrappers above and update any hardcoded fallback digests in platform `EmbeddedHost` sources if present.

## Architecture boundary

Sync scripts copy **public** bundle inputs only (manifests, certified `runtime.wasm`, example capability trees). They must not import private Traverse internals or invent business fields.
