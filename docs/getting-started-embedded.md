# Getting Started — Embedded Traverse Apps

Build a Traverse app where **business logic lives once in WASM** and every UI shell only submits input and renders runtime-owned output. This guide uses platforms that already embed successfully today.

> **All primary platforms embed today.** Full shipping guide: [`production-playbook.md`](production-playbook.md).  
> Sidecar docs remain in [`traverse-runtime.md`](traverse-runtime.md) (deprecated appendix only).

## Mental model

| Layer | Responsibility | Lives in |
|---|---|---|
| WASM agents + workflow | Business decisions (title, tags, recommendation, …) | Traverse examples / capabilities |
| App + component manifests | Bundle identity, component digests, workflow wiring | This repo — `manifests/<app>/` |
| Platform UI shell | Submit input, render runtime fields, show status | This repo — `apps/<app>/<platform>/` |

The UI **never** computes business fields. Same note in → same runtime-owned fields out, on every embedded platform.

## Prerequisites

- **Node.js 24+** (see `.nvmrc`) — for the Web React shell
- **Rust 1.78+** via [rustup](https://rustup.rs/) — for Linux GTK / CLI
- A local **Traverse** checkout with example WASM (set `TRAVERSE_REPO`)

```bash
git clone https://github.com/traverse-framework/Traverse.git ../Traverse
export TRAVERSE_REPO="$(cd ../Traverse && pwd)"
```

## 1. Clone App-References and install

```bash
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps
npm install
```

## 2. Run embedded traverse-starter on Web (no sidecar)

Sync the application bundle into the Vite public tree, then start the shell:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_web_starter_bundle.sh
npm run dev    # apps/traverse-starter/web-react
```

Bundle sync rules (digest pin, shared core, platform wrappers): [`runtime-bundle-sync.md`](runtime-bundle-sync.md).

Per-platform packaging + release evidence: [`production-packaging.md`](production-packaging.md).

Open `http://localhost:5173`. When the runtime strip shows the embedded host is ready:

1. Submit a fixed note, e.g. `Meeting with Alice about project X`
2. Confirm the output panel shows runtime-owned fields: **title**, **tags**, **note type**, **suggested next action**, **status**
3. Confirm you did **not** start `traverse-cli serve`

Details: [`apps/traverse-starter/web-react/README.md`](../apps/traverse-starter/web-react/README.md).

## 3. Run the same app on Linux GTK or CLI

Link the public `traverse-embedder` crate from your Traverse checkout, then build:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh

cd apps/traverse-starter
cargo test -p traverse-core-rs
```

**CLI:**

```bash
cargo run -p traverse-starter-cli -- run --note "Meeting with Alice about project X"
cargo run -p traverse-starter-cli -- health
```

**Linux GTK** (Ubuntu 22.04+ with `libgtk-4-dev` / `libadwaita-1-dev`):

```bash
sudo apt install libgtk-4-dev libadwaita-1-dev   # once
cargo run -p traverse-starter-gtk
```

Submit the same note. Zone 1 should show **Embedded**; output fields must match the Web run (same runtime-owned shape).

- [`apps/traverse-starter/cli-rust/README.md`](../apps/traverse-starter/cli-rust/README.md)
- [`apps/traverse-starter/linux-gtk/README.md`](../apps/traverse-starter/linux-gtk/README.md)

## 4. Where to change business logic vs UI

| Want to change… | Edit… | Do not… |
|---|---|---|
| Title / tags / next action rules | Traverse WASM agents + `traverse-starter.pipeline` workflow | Hard-code fields in React/Swift/Compose |
| Which components the app loads | `manifests/traverse-starter/` | Invent fake execute/poll stubs in the UI |
| Layout, copy, accessibility | `apps/traverse-starter/<platform>/` | Import private Traverse internals |

Showcase workflow: `traverse-starter.pipeline` (`validate` → `process` → `summarize`). See [`embedded-runtime-plan.md`](embedded-runtime-plan.md).

## 5. Add another platform UI

Follow the ordered recipe: [`add-platform-client.md`](add-platform-client.md).

Checklist for a new shell (or promoting a sidecar client to embedded):

1. Depend on the **public** platform embedder SDK (Web: `traverse-embedder-web`; Rust: `traverse-embedder`; Swift / .NET / Android vendors as shipped)
2. Bundle `manifests/<app>/` + WASM artifacts for the host loader
3. Submit workflow input; subscribe to embedder events; render only runtime-owned fields
4. Document **Runtime mode: Embedded** in that platform’s README
5. Do **not** add HTTP sidecar URL config to primary shells — appendix only ([`traverse-runtime.md`](traverse-runtime.md))
6. Extend `scripts/ci/embedded_smoke.sh` (or ensure the new slice skips with an explicit reason until its runner exists)

## Platform matrix (current)

| Platform | Runtime mode | Notes |
|---|---|---|
| Web React | **Embedded** | [#113](https://github.com/traverse-framework/reference-apps/issues/113) shipped |
| Linux GTK | **Embedded** | [#117](https://github.com/traverse-framework/reference-apps/issues/117) shipped |
| Rust CLI | **Embedded** | [#117](https://github.com/traverse-framework/reference-apps/issues/117) shipped |
| Android | **Embedded** | [#115](https://github.com/traverse-framework/reference-apps/issues/115) shipped |
| iOS / macOS | **Embedded** | [#114](https://github.com/traverse-framework/reference-apps/issues/114) shipped |
| Windows | **Embedded** | [#116](https://github.com/traverse-framework/reference-apps/issues/116) shipped |


Same matrix for `doc-approval` (embedded Web / Linux / CLI with `doc-approval.pipeline`). Status labels in the root [`README.md`](../README.md) **Platform clients** table remain the source of truth.

## Validation — embedded smoke

Prove the production path without `traverse-cli serve`:

```bash
export TRAVERSE_REPO=/path/to/Traverse
export EMBEDDED_SMOKE_EXPECT=linux   # require web + CLI; skip native SDKs with reason
bash scripts/ci/embedded_smoke.sh
```

- **Web:** sync bundle → `BundleEmbedder` + `NodeFsBundleLoader` → init + workflow invoke  
- **CLI:** `phase2_link_traverse.sh` → `cargo run -p traverse-starter-cli -- health --json` → `Embedded` / `Ready`  
- **Android / Swift / Windows:** digest-check committed `runtime/runtime.wasm`; full SDK tests when tools exist  
- Hard-fails unless validate/process/summarize runtime-owned fields are present (smoke WASI fixtures under `scripts/ci/fixtures/traverse-starter-smoke-agents/`)

CI runs this with `EMBEDDED_SMOKE_EXPECT=linux` on every PR (see `.github/workflows/ci.yml`).

## Related docs

- [`production-playbook.md`](production-playbook.md) — embedded-first production playbook
- [`embedded-runtime-plan.md`](embedded-runtime-plan.md) — Phase 3 architecture
- [`production-reference-plan.md`](production-reference-plan.md) — Phase 4 kit roadmap
- [`traverse-starter-plan.md`](traverse-starter-plan.md) — app plan across phases
- [`traverse-runtime.md`](traverse-runtime.md) — **Dev sidecar appendix** (deprecated)
- [`youaskm3-starter-kit.md`](youaskm3-starter-kit.md) — browser consumer adoption path
