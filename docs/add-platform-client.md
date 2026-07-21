# Recipe: add a new OS client from App-References

Step-by-step pattern for adding (or promoting) a **primary** product-shell UI on a new OS, cloned from the shipped Phase 3 embeds. Use **traverse-starter** as the reference kit; mirror the same steps for `doc-approval` / `meeting-notes`.

Related:

- Shipping guide: [`production-playbook.md`](production-playbook.md)
- Bundle pin/sync: [`runtime-bundle-sync.md`](runtime-bundle-sync.md)
- Packaging / `registry_ref` (docs only): [`production-packaging.md`](production-packaging.md)
- Primary vs secondary: root [`README.md`](../README.md) · [`adopted-platform-clients.md`](adopted-platform-clients.md)
- Production PR DoD: `.github/pull_request_template.md`

## Non-goals

- **No business logic in the UI** — title, tags, note type, next action, status (and domain equivalents) come from the runtime only
- **No private Traverse imports** — public embedder packages / vendored SDKs only
- **No sidecar as the shipping path** — embedded host; HTTP is appendix / Trace Explorer only ([`traverse-runtime.md`](traverse-runtime.md))
- Do **not** copy secondary kit patterns (`react-demo`, etc.) into primary shells without caveats

## Prerequisites

1. App manifests exist under `manifests/<app>/`
2. Public platform embedder SDK is available for the OS (vendor or package reference)
3. Project 2 ticket claimed (`AGENTS.md` pre-flight) with production-shaped DoD

## Ordered steps

### 1. Map the file layout from a shipped twin

| Concern | Web example | Native examples |
|---|---|---|
| App shell | `apps/<app>/web-react/` | `…/android-compose/`, `…/ios-swift/`, `…/macos-swift/`, `…/windows-winui/`, `…/linux-gtk/`, `…/cli-rust/` |
| Shared host helpers | (in-app `src/host/`) | `TraverseCore` / `DocApprovalCore` / `traverse-core-rs` |
| Embedder SDK | `vendor/traverse-embedder-web` | `vendor/traverse-embedder-swift`, `vendor/traverse-embedder-dotnet`, Rust crate `traverse-embedder` |
| Bundle destination | `…/web-react/public/bundles/<app>/` | platform Resources / assets / Assets paths |
| Sync wrapper | `scripts/ci/sync_web_*_bundle.sh` | `sync_android_*`, `sync_swift_*`, `sync_winui_*` |

Open a merged PR for the closest OS (#113 Web, #117 Linux/CLI, #115 Android, #114 Swift, #116 WinUI) and copy **structure**, not business rules.

### 2. Depend on the public embedder

| OS | Public package |
|---|---|
| Web / TypeScript | `traverse-embedder-web` (vendored under `vendor/traverse-embedder-web`; refresh via `ORIGIN.md`) |
| Apple (iOS / macOS) | `TraverseEmbedder` Swift package (`vendor/traverse-embedder-swift`) + digest-pinned `runtime.wasm` |
| Windows | .NET `TraverseEmbedder` (`vendor/traverse-embedder-dotnet`) + `runtime.wasm` |
| Android | Kotlin `dev.traverse.embedder` (see Android README) + `runtime.wasm` |
| Linux / CLI | Rust `traverse-embedder` (git dependency from Traverse) via `traverse-core-rs` |

Refresh vendor trees only with the recipes in each `vendor/*/ORIGIN.md`, then re-run sync wrappers.

### 3. Wire digest-pinned bundle sync

1. Add or reuse a thin wrapper in `scripts/ci/` that calls `sync_bundle_core.sh` (keep existing naming)
2. Document the destination path in the platform README
3. Run:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_<platform>_<app>_bundle.sh
```

4. Confirm `runtime-release.json` sha256 matches `runtime.wasm` when the platform uses the native host pin ([`runtime-bundle-sync.md`](runtime-bundle-sync.md))

### 4. Implement Zone 1 Embedded UX

Per [`design-language.md`](design-language.md):

- Show **Runtime mode: Embedded** (not a required loopback URL)
- Submit workflow input through the public embedder API
- Render only runtime-owned fields from embedder events / output
- Loading / error / ready states driven by host status + events

### 5. Tests with SDK doubles

- Unit tests inject `EmbedderTestDouble` / `InMemoryTraverseEmbedder` (or platform equivalent)
- Assert UI rendering of **fixture** runtime-owned output — never compute those fields in the test harness beyond what the double emits
- Keep production `BundleEmbedder` / `RuntimeTraverseEmbedder` path free of faked business logic

### 6. Docs + Project 2

- Platform README: **Runtime mode: Embedded**, sync command, build/test commands
- Update root README platform table + `docs/design-language.md` reference row when shipping
- PR body uses production checklist (embed, pin/sync, SDK doubles, docs, CI)

### 7. CI

- Linux-runnable slices: ensure `scripts/ci/embedded_smoke.sh` covers or explicitly `SKIP`s with reason
- Native build gates: follow tiered plan in `docs/quality-standards.md` and Project 2 `native-ci-android-gtk-required` (do not invent a sidecar CI path)
- Local: `npm` gates for Web; `cargo` / `gradle` / `xcodebuild` / `dotnet` as applicable

## Checklist (copy into the Project 2 ticket DoD)

- [ ] Public embedder dependency only
- [ ] Sync wrapper + pin documented
- [ ] Zone 1 Embedded UX
- [ ] SDK double unit tests
- [ ] README + shipping doc touchpoints
- [ ] CI / smoke skip-or-fail contract understood
- [ ] Project 2 ticket + PR with production DoD sections

## Validation

Pick an existing platform and walk this recipe:

```bash
# Example: confirm Web starter files exist for each step
test -d apps/traverse-starter/web-react/src/host
test -f vendor/traverse-embedder-web/ORIGIN.md
test -f scripts/ci/sync_web_starter_bundle.sh
grep -q 'Runtime mode: Embedded' apps/traverse-starter/web-react/README.md
```
