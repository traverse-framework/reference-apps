# traverse-starter (Linux GTK4)

Native Linux client for the `traverse-starter` reference app. Uses the shared `traverse-core-rs` crate with the public **`traverse-embedder`** SDK (Phase 3 embedded runtime). No `traverse-cli serve` sidecar is required.

## Prerequisites

- **Ubuntu 22.04+** (or equivalent distro with GTK4 + libadwaita)
- **Rust 1.78+** via [rustup](https://rustup.rs/)
- **System dependencies**:

```bash
sudo apt install libgtk-4-dev libadwaita-1-dev
```

- **Traverse checkout** (sibling recommended) with `traverse-embedder` and example WASM:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh   # from App-References root
```

`traverse-core-rs` depends on `traverse-embedder` from the Traverse git repo.

## Bundle configuration

Open **Preferences** and optionally set:

- **Workspace** — default `local-default`
- **Bundle manifest path** — defaults to auto-discover `manifests/traverse-starter/app.manifest.json`

Or set `TRAVERSE_STARTER_MANIFEST` to the absolute path of `app.manifest.json`.

## Build and run

```bash
cd apps/traverse-starter
cargo build -p traverse-starter-gtk
cargo test -p traverse-core-rs -p traverse-starter-gtk
cargo run -p traverse-starter-gtk
```

## Architecture

| File | Role |
|---|---|
| `../traverse-core-rs` | Shared `EmbeddedRuntime` over `traverse-embedder` |
| `client.rs` | Re-exports embedded host types |
| `execution_state.rs` | Shell UI phase / Ready status |
| `ui/main_window.rs` | Zones 1–3 per design-language |
| `ui/preferences.rs` | Workspace + optional manifest path |

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md). Zone 1 shows **Embedded** runtime mode.
