# traverse-starter (Linux GTK4)

Native Linux client for the `traverse-starter` reference app. Uses the shared `traverse-core-rs` crate for HTTP command dispatch and SSE app-state events (same pattern as `web-react`).

## Prerequisites

- **Ubuntu 22.04+** (or equivalent distro with GTK4 + libadwaita)
- **Rust 1.78+** via [rustup](https://rustup.rs/)
- **System dependencies**:

```bash
sudo apt install libgtk-4-dev libadwaita-1-dev
```

- **Traverse runtime** running locally:

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

## Runtime URL configuration

Open **Preferences** (gear icon in the header bar) and set:

- **Runtime URL** — default `http://127.0.0.1:8787`
- **Workspace** — default `local-default`

Values persist to `~/.config/traverse-starter/settings.json`.

## Build and run

Prefer the workspace root so the shared crate resolves cleanly:

```bash
cd apps/traverse-starter
cargo build -p traverse-starter-gtk
cargo test -p traverse-core-rs
cargo run -p traverse-starter-gtk
```

## Architecture

| File | Role |
|---|---|
| `../traverse-core-rs` | Shared HTTP `send_command` + SSE `subscribe_events` |
| `client.rs` | Re-exports `traverse-core-rs` |
| `execution_state.rs` | Shell UI phase / online status (not runtime transitions) |
| `ui/main_window.rs` | `AdwApplicationWindow` — input, output, header health strip |
| `ui/preferences.rs` | Runtime URL + workspace dialog |

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
