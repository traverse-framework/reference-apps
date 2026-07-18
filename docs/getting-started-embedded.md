# Getting Started — Embedded Traverse Apps

Build a Traverse app where **business logic lives once in WASM** and every UI shell only submits input and renders runtime-owned output. This guide uses platforms that already embed successfully today.

> **Not this path?** Apple / Android / Windows clients still use the HTTP sidecar interim until [#114](https://github.com/traverse-framework/reference-apps/issues/114)–[#116](https://github.com/traverse-framework/reference-apps/issues/116) land. See each platform README’s **Runtime mode** line and [`traverse-runtime.md`](traverse-runtime.md).

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

Checklist for a new shell (or promoting a sidecar client to embedded):

1. Depend on the **public** platform embedder SDK (Web: `traverse-embedder-web`; Rust: `traverse-embedder`; others when [#114](https://github.com/traverse-framework/reference-apps/issues/114)–[#116](https://github.com/traverse-framework/reference-apps/issues/116) ship)
2. Bundle `manifests/<app>/` + WASM artifacts for the host loader
3. Submit workflow input; subscribe to embedder events; render only runtime-owned fields
4. Document **Runtime mode: embedded** in that platform’s README
5. Keep HTTP sidecar docs only as an interim path until cutover

## Platform matrix (current)

| Platform | Runtime mode | Notes |
|---|---|---|
| Web React | **Embedded** | [#113](https://github.com/traverse-framework/reference-apps/issues/113) shipped |
| Linux GTK | **Embedded** | [#117](https://github.com/traverse-framework/reference-apps/issues/117) shipped |
| Rust CLI | **Embedded** | [#117](https://github.com/traverse-framework/reference-apps/issues/117) shipped |
| iOS / macOS | HTTP sidecar (interim) | Embed blocked on [#114](https://github.com/traverse-framework/reference-apps/issues/114) |
| Android | HTTP sidecar (interim) | Embed blocked on [#115](https://github.com/traverse-framework/reference-apps/issues/115) |
| Windows | HTTP sidecar (interim) | Embed blocked on [#116](https://github.com/traverse-framework/reference-apps/issues/116) |

Same matrix for `doc-approval` (embedded Web / Linux / CLI with `doc-approval.pipeline`). Status labels in the root [`README.md`](../README.md) **Platform clients** table remain the source of truth.

## Related docs

- [`embedded-runtime-plan.md`](embedded-runtime-plan.md) — Phase 3 architecture
- [`traverse-starter-plan.md`](traverse-starter-plan.md) — app plan across phases
- [`traverse-runtime.md`](traverse-runtime.md) — **Dev sidecar (Phase 1/2 interim)** only
- [`youaskm3-starter-kit.md`](youaskm3-starter-kit.md) — browser consumer adoption path
