# traverse-starter (Rust CLI)

Terminal client for the `traverse-starter` reference app. Phase 1 uses HTTP polling against the public Traverse HTTP/JSON API (spec 033) — same flow as `web-react` and the native GUI clients.

## Prerequisites

- **Rust 1.78+** via [rustup](https://rustup.rs/)
- **Traverse runtime** running locally:

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

## Build and install

```bash
cd apps/traverse-starter/cli-rust
cargo build --release
cargo test
cargo install --path .   # installs `traverse-starter` binary to ~/.cargo/bin
```

## Usage

```bash
# Human-readable output
traverse-starter run --note "Meeting with Alice about project X"

# Machine-readable JSON
traverse-starter run --note "..." --json

# Health check
traverse-starter health
traverse-starter health --json

# Override runtime URL and workspace
traverse-starter run --base-url http://192.168.1.42:8787 --workspace my-workspace --note "..."
```

Environment variables:

| Variable | Default |
|---|---|
| `TRAVERSE_BASE_URL` | `http://127.0.0.1:8787` |
| `TRAVERSE_WORKSPACE` | `local-default` |

## Architecture

| File | Role |
|---|---|
| `client.rs` | Blocking `reqwest` HTTP client |
| `commands/run.rs` | Execute + poll loop |
| `commands/health.rs` | `/healthz` check |
| `output.rs` | Human (colored) and JSON formatters |

## Phase 2 (not implemented)

SSE streaming when Traverse ships [#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527). Shared client moves to `traverse-core-rs` ([#59](https://github.com/traverse-framework/reference-apps/issues/59)).
