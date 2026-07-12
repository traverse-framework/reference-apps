# traverse-starter (Rust CLI)

Terminal client for the `traverse-starter` reference app. Uses the shared `traverse-core-rs` crate for HTTP command dispatch and SSE app-state events (same pattern as `web-react`).

## Prerequisites

- **Rust 1.78+** via [rustup](https://rustup.rs/)
- **Traverse runtime** running locally:

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

## Build and install

Prefer the workspace root so the shared crate resolves cleanly:

```bash
cd apps/traverse-starter
cargo build -p traverse-starter-cli --release
cargo test -p traverse-starter-cli -p traverse-core-rs
cargo install --path cli-rust   # installs `traverse-starter` binary to ~/.cargo/bin
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
| `../traverse-core-rs` | Shared HTTP `send_command` + SSE `subscribe_events` |
| `client.rs` | Re-exports `traverse-core-rs` |
| `commands/run.rs` | Submit note + wait for SSE terminal result |
| `commands/health.rs` | `/healthz` check |
| `output.rs` | Human (colored) and JSON formatters |
