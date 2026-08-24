# Production packaging

How App-References packages **primary** product shells for multi-OS embed: digest-pinned runtime, per-platform bundle layout, build/test, and release evidence. Secondary kits are out of scope here — see [`adopted-platform-clients.md`](adopted-platform-clients.md).

**Architecture boundary:** the UI never computes business fields (title, tags, note type, next action, status, or domain equivalents). Packaging only moves **public** manifests, certified `runtime.wasm`, and capability artifacts.

Related: [`app-manifest-schema.md`](app-manifest-schema.md) · [`runtime-bundle-sync.md`](runtime-bundle-sync.md) · [`production-playbook.md`](production-playbook.md) · [`add-platform-client.md`](add-platform-client.md) · [`quality-standards.md`](quality-standards.md)

## Pin source (all native embeds)

| Artifact | Source |
|---|---|
| `runtime.wasm` | `$TRAVERSE_REPO/runtime/runtime.wasm` |
| `runtime-release.json` | `$TRAVERSE_REPO/runtime/runtime-release.json` (`sha256` must match WASM) |
| App manifests | `manifests/<app>/` in this repo |

```bash
export TRAVERSE_REPO=/path/to/Traverse
# wrappers call scripts/ci/sync_bundle_core.sh and verify the digest
bash scripts/ci/sync_<platform>_<app>_bundle.sh
```

## Per-platform packaging

Paths below use **traverse-starter**; replace with `doc-approval` (or other primary apps) as needed.

### Web (React)

| | |
|---|---|
| Shell | `apps/<app>/web-react/` |
| Bundle layout | `public/bundles/<app>/` — app + component manifests + `_traverse/` examples/workflows/contracts |
| Sync | `bash scripts/ci/sync_web_starter_bundle.sh` (`--runtime none`, `--traverse-assets required`) |
| Embedder | `vendor/traverse-embedder-web` (`BundleEmbedder` + `FetchBundleLoader`) |
| Build / test | From repo root: `npm run typecheck && npm run lint && npm run test` (workspace) |
| Release evidence | Package version in app `package.json`; embedder version in vendor `package.json` / `ORIGIN.md`; capability digests in component manifests |

Sidecar is **not** part of Web packaging. Optional interim only: [`traverse-runtime.md`](traverse-runtime.md).

### Linux GTK + CLI (Rust)

| | |
|---|---|
| Shells | `apps/<app>/linux-gtk/`, `apps/<app>/cli-rust/`, shared `traverse-core-rs` / `doc-approval-core-rs` |
| Bundle layout | Manifests via `manifests/<app>/` + `phase2_link_traverse.sh` (`_traverse` symlink) |
| Sync / link | `bash scripts/ci/phase2_link_traverse.sh` |
| Embedder | Public Rust `traverse-embedder` (git dep from Traverse) |
| Build / test | `cd apps/<app> && cargo test -p <core> && cargo run -p <cli> -- health --json` |
| Release evidence | Cargo package versions; `health --json` reports `runtime_mode=Embedded`; link to Traverse embedder commit/tag in `Cargo.lock` |

### Android (Compose)

| | |
|---|---|
| Shell | `apps/<app>/android-compose/` |
| Bundle layout | `app/src/main/assets/bundles/<app>/runtime/{runtime.wasm,runtime-release.json}` + `manifests/` |
| Sync | `bash scripts/ci/sync_android_starter_bundle.sh` |
| Embedder | Kotlin `dev.traverse.embedder` (see platform README) |
| Build / test | `./gradlew :app:assembleDebug :app:testDebugUnitTest` |
| Release evidence | `runtime-release.json` (`runtime_version`, `bridge_version`, `sha256`); app `versionName` / `versionCode` |

### iOS + macOS (Swift)

| | |
|---|---|
| Shells | `apps/<app>/ios-swift/`, `apps/<app>/macos-swift/` + shared `*Core` package |
| Bundle layout | `Resources/bundles/<app>/runtime/` + root app/component manifests |
| Sync | `bash scripts/ci/sync_swift_starter_bundle.sh` (both destinations) |
| Embedder | `vendor/traverse-embedder-swift` + XCFramework URL in `Package.swift` |
| Build / test | `xcodebuild` schemes documented in [`quality-standards.md`](quality-standards.md) |
| Release evidence | `runtime-release.json` pin; Swift package versions; XCFramework release URL |

### Windows (WinUI 3)

| | |
|---|---|
| Shell | `apps/<app>/windows-winui/` |
| Bundle layout | `Assets/bundles/<app>/runtime/` + root manifests (+ optional `_traverse/` trees) |
| Sync | `bash scripts/ci/sync_winui_starter_bundle.sh` |
| Embedder | `vendor/traverse-embedder-dotnet` |
| Build / test | `dotnet build … -c Release` and `dotnet test … -c Release` |
| Release evidence | `runtime-release.json` pin; NuGet/project versions; vendor `ORIGIN.md` |

## Release-evidence checklist

Before tagging or cutting a primary-shell release:

1. [ ] `runtime-release.json` sha256 matches bundled `runtime.wasm` (native) or component digests match synced example WASM (Web)
2. [ ] Platform README still says **Runtime mode: Embedded**
3. [ ] Unit tests use public SDK doubles only — no invented business fields
4. [ ] `bash scripts/ci/embedded_smoke.sh` green for required Linux slices (`web`, `rust-cli`) when cutting from CI
5. [ ] Record embedder / bridge / runtime version tuple in release notes (from `runtime-release.json` + vendor ORIGIN)

## Sidecar (optional interim only)

HTTP `traverse-cli serve` is **not** a packaging input for primary shells. Document it only as debug/appendix ([`traverse-runtime.md`](traverse-runtime.md)). Trace Explorer uses the embedded Trace API (`embed-trace-explorer`).

---

## `registry_ref` consumer contract

Docs-only contract for how primary App-References shells consume public registry capabilities via `registry_ref`. **Full primary cutover landed:** all six kit components under `manifests/{traverse-starter,doc-approval,meeting-notes}/components/` use `registry_ref` (Project 2 `registry-ref-full-kit-cutover`; first slice was `registry-ref-starter-process`).

Governing Traverse / Registry specs:

- [`054-public-scope-registry-ref`](https://github.com/traverse-framework/Traverse/blob/main/specs/054-public-scope-registry-ref/spec.md)
- [`055-registry-sync`](https://github.com/traverse-framework/Traverse/blob/main/specs/055-registry-sync/spec.md)
- Registry [`008-reference-capability-publication`](https://github.com/traverse-framework/registry/blob/main/specs/008-reference-capability-publication/spec.md) / [`005-yank-deprecation`](https://github.com/traverse-framework/registry/blob/main/specs/005-yank-deprecation/spec.md) — seeds at `1.0.1`; stub `1.0.0` yanked

## Status

| Layer | Today | Next |
|---|---|---|
| Component manifests under `manifests/` | **All six primary components** (+ Loop WF1) use `registry_ref` | Keep ranges; no local-path reintroduction |
| Sync / packaging | [`runtime-bundle-sync.md`](runtime-bundle-sync.md) + **gated** `sync_bundle_materialize_registry_refs` (default **on**) | Retire rewrite once hosts resolve `registry_ref` offline from Spec 520 cache |
| Spec 520 (Traverse) | `#860` closed — Rust `HostRegistryCache` + web standalone prepare/resolve APIs | Web `BundleEmbedder` still requires `wasm_binary_path`; native Spec 107 adopt incomplete |
| App-Refs ticket | `retire-registry-ref-materialize` | Phase A: gate/tests/docs; full delete blocked on Traverse BundleEmbedder + Spec 107 |

**Checked-in source of truth** for every primary component is `registry_ref` only (no local `contract_path` / `wasm_*` on source manifests). Platform sync **materializes** local wasm paths into destination bundles by default (`APP_REFS_MATERIALIZE_REGISTRY_REFS=1`) for FetchBundleLoader / native bridges that still require `wasm_binary_path`. Set `APP_REFS_MATERIALIZE_REGISTRY_REFS=0` to leave destination `registry_ref` intact (hosts must use Traverse prepare + verified cache — not production-ready for all App-Refs shells yet).

## Intended component shape

Exactly one capability source per component (spec 054 FR-007). Primary kit components use **registry only**:

```json
{
  "component_id": "traverse-starter.validate-component",
  "capability_id": "traverse-starter.validate",
  "registry_ref": {
    "namespace": "traverse-starter",
    "id": "traverse-starter.validate",
    "version_range": "^1.0.0"
  }
}
```

Same shape for `traverse-starter.process` / `summarize`, `doc-approval.analyze` / `recommend`, and `meeting-notes.process`.

`registry_ref` fields (spec 054 FR-008): non-empty `namespace`, `id`, and `version_range`. Do **not** also declare local `contract_path` / `wasm_*` on the same component.

**Destination-only local fields** (after sync materialize) are allowed in platform bundle trees — never on checked-in `manifests/` sources.

## Resolve / sync flow (intended)

1. Publisher lands capability in the public registry (Traverse registry PR / seed flow — outside this repo).
2. Consumer runs `traverse-cli registry sync` so the **local public tier** contains the record (spec 055).
3. App registration / embed host resolves `registry_ref` **only** against that synced public tier — no live network fallback (spec 054 FR-010).
4. At registration time, artifacts are fetched, **digest-verified**, and stored in a local content-addressed cache (spec 054 FR-011).
5. Runtime execution reads only local durable state + cached artifacts.

If sync has not run, registration must fail with a stable error that `traverse-cli registry sync` is required (spec 054 scenario 2).

## Digests vs registry

| Concern | Local-path (legacy) | `registry_ref` (primary kit) |
|---|---|---|
| WASM integrity | `wasm_digest` on the component manifest | Published digest from the registry record; verified at fetch (destination materialize recomputes from bytes) |
| Runtime host pin | `$TRAVERSE_REPO/runtime/runtime-release.json` via sync wrappers | Unchanged — host pin is orthogonal to capability `registry_ref` |
| App identity | `manifests/<app>/app.manifest.json` component digests | App manifest still lists components; capability bytes may come from cache / materialized tree |

## What stays outside `registry_ref` (for now)

- Native digest-pinned `runtime/runtime.wasm` sync ([`runtime-bundle-sync.md`](runtime-bundle-sync.md)) — host pin is orthogonal to capability `registry_ref`
- Secondary/demo apps that are not primary shells

**Primary cutover (landed):** all six kit components via `registry-ref-starter-process` + `registry-ref-full-kit-cutover`.

## Agent / playbook rules

- Do **not** reintroduce local `contract_path` / `wasm_*` on checked-in primary `manifests/` components.
- Platform sync may materialize `registry_ref` → local wasm in **destination** bundles only (default on). Do not flip `APP_REFS_MATERIALIZE_REGISTRY_REFS=0` for primary shells until BundleEmbedder / native adopt paths are proven in smoke.
- Prefer `version_range: "^1.0.0"` so yanked stub `1.0.0` is skipped and live `1.0.1` is selected when the resolver is yank-aware (registry spec 005).
- UI remains a rendering layer — registry adoption does not move business field computation into App-References.

## Related

- Plan: [`production-reference-plan.md`](production-reference-plan.md)
- Sync: [`runtime-bundle-sync.md`](runtime-bundle-sync.md)
- Playbook: [`production-playbook.md`](production-playbook.md)
