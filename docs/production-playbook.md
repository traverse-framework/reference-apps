# Production Playbook — Embedded Multi-OS Traverse Apps

**Audience:** humans and agents cloning this repo to ship a real multi-OS Traverse app.

**Default path:** embedded WASM runtime in every UI shell.  
**Not the default:** `traverse-cli serve` HTTP sidecar (appendix only — [`traverse-runtime.md`](traverse-runtime.md)).

Related plans: [`production-reference-plan.md`](production-reference-plan.md) (Phase 4 kit), [`embedded-runtime-plan.md`](embedded-runtime-plan.md) (Phase 3 architecture), [`getting-started-embedded.md`](getting-started-embedded.md) (hands-on).

---

## 1. Mental model

| Layer | Owns | Lives in |
|---|---|---|
| WASM agents + workflows | Business decisions (title, tags, recommendations, …) | Traverse examples / capabilities |
| App + component manifests | Bundle identity, digests, workflow wiring | This repo — `manifests/<app>/` |
| Platform UI shell | Submit input, render runtime fields, show status | This repo — `apps/<app>/<platform>/` |

Rules:

1. UI never computes business fields.
2. Use **public** platform embedder SDKs only (`traverse-embedder-web`, `traverse-embedder`, Kotlin/Swift/.NET packages).
3. Same note in → same runtime-owned fields out on every OS.
4. Production builds do **not** require `127.0.0.1:8787`.

---

## 2. Primary product shells (copy these)

| App | Platforms (embedded) | Notes |
|---|---|---|
| **traverse-starter** | Web, Linux GTK, CLI, Android, Windows, iOS, macOS | Reference kit — start here |
| **doc-approval** | Same seven platforms | Second domain + pipeline |
| **meeting-notes** | Web today | Primary product shell; multi-OS embed showcase is [#179](https://github.com/traverse-framework/reference-apps/issues/179) |

**Not primary product shells** (do not treat as the production kit bar — [#186](https://github.com/traverse-framework/reference-apps/issues/186)):

| App | Status |
|---|---|
| trace-explorer | **Debugger exception** — named HTTP until Traverse embeds a trace API ([#183](https://github.com/traverse-framework/reference-apps/issues/183)); not a secondary “product” kit |
| react-demo, android-demo, macos-demo, youaskm3-starter-kit, browser-consumer | **Adopted / secondary** demos & kits — lighter maintenance; not merge-blocking `embedded_smoke` targets — see [`adopted-platform-clients.md`](adopted-platform-clients.md) |

---

## 3. First run (Web — production path)

```bash
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps
npm install

git clone https://github.com/traverse-framework/Traverse.git ../Traverse
export TRAVERSE_REPO="$(cd ../Traverse && pwd)"

bash scripts/ci/sync_web_starter_bundle.sh
npm run dev    # traverse-starter embedded web shell @ :5173
```

Do **not** start `traverse-cli serve`. Confirm the UI shows **Embedded** / ready, then submit a note and check runtime-owned fields.

Full walkthrough: [`getting-started-embedded.md`](getting-started-embedded.md).

---

## 4. Linux GTK / CLI

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
cd apps/traverse-starter
cargo run -p traverse-starter-cli -- health --json   # Embedded / Ready
cargo run -p traverse-starter-cli -- run --note "…"
# GTK (optional): apt install libgtk-4-dev libadwaita-1-dev && cargo run -p traverse-starter-gtk
```

---

## 5. Native mobile / desktop

Each primary shell README starts with **`Runtime mode: Embedded`**.

| Platform | Sync helper | Typical verify |
|---|---|---|
| Android | `scripts/ci/sync_android_starter_bundle.sh` | `./gradlew test` |
| iOS / macOS | `scripts/ci/sync_swift_starter_bundle.sh` | Xcode Run / `swift test` |
| Windows | `scripts/ci/sync_winui_starter_bundle.sh` | Visual Studio / `dotnet test` |

Digest-pinned `runtime/runtime.wasm` + `runtime-release.json` must match. Shared sync core: [`runtime-bundle-sync.md`](runtime-bundle-sync.md) / `scripts/ci/sync_bundle_core.sh`.

---

## 6. Prove the path (CI)

```bash
export TRAVERSE_REPO=/path/to/Traverse
export EMBEDDED_SMOKE_EXPECT=linux
bash scripts/ci/embedded_smoke.sh
```

- Merge-blocking on PR CI for **Web + CLI** with **runtime-owned pipeline output** required
- Smoke overlays deterministic WASI fixtures (`scripts/ci/fixtures/traverse-starter-smoke-agents/`) until Traverse example agents ship non-stub WASM
- Other platforms: skip-with-reason when SDK missing; digest-check always

---

## 7. Add another OS client

High-level checklist (full recipe: [#178](https://github.com/traverse-framework/reference-apps/issues/178)):

1. Depend on the public embedder for that OS  
2. Bundle manifests + digest-pinned runtime / components  
3. Submit workflow input; subscribe to events; render runtime fields only  
4. Document **Runtime mode: Embedded** in the platform README  
5. Extend `embedded_smoke.sh` slice (or digest check) when a runner exists (#88)

---

## 8. Sidecar appendix (deprecated)

Use [`traverse-runtime.md`](traverse-runtime.md) only for:

- Historical Phase 1/2 integration  
- Trace Explorer (named exception)  
- Legacy `phase1_smoke.sh` / nightly sidecar checks  

Do **not** copy sidecar URL configuration into new primary product shells. Removal of leftover HTTP clients: [#180](https://github.com/traverse-framework/reference-apps/issues/180) (after smoke stays green).

---

## 9. Definition of done (shipping a shell)

- [ ] Public embedder only — no private Traverse internals  
- [ ] No business field computation in UI  
- [ ] README declares **Runtime mode: Embedded**  
- [ ] Bundle sync documented; digests pinned  
- [ ] `embedded_smoke` slice green on the expected runner (or documented skip)  
- [ ] No required loopback URL in production config  
