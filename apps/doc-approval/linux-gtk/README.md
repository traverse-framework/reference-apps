# doc-approval (Linux GTK4)

Native Linux submitter client for the `doc-approval` reference app. Phase 1 uses HTTP polling against the public Traverse HTTP/JSON API (spec 033) — same flow as `web-react` and the other native clients.

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

Values persist to `~/.config/doc-approval/settings.json`.

## Build and run

```bash
cd apps/doc-approval/linux-gtk
cargo build
cargo test
cargo run
```

## Architecture

| File | Role |
|---|---|
| `client.rs` | `reqwest` HTTP client (execute / poll / trace / healthz) |
| `execution_state.rs` | `Arc<Mutex<ExecutionState>>` polling state machine |
| `ui/main_window.rs` | `AdwApplicationWindow` — document input, analysis output, header health strip |
| `ui/preferences.rs` | Runtime URL + workspace dialog |

The UI renders runtime-provided output fields only (`docType`, `parties`, `amounts`, `confidence`, `recommendation`).

## Phase 2 (not implemented)

SSE subscription when Traverse ships [#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527).

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
