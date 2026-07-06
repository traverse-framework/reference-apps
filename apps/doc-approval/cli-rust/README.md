# doc-approval (Rust CLI)

Terminal client for the `doc-approval` reference app. Phase 1 uses HTTP polling against the public Traverse HTTP/JSON API (spec 033) — same flow as `web-react` and the native GUI clients.

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
cd apps/doc-approval/cli-rust
cargo build --release
cargo test
cargo install --path .   # installs `doc-approval` binary to ~/.cargo/bin
```

## Usage

```bash
# Human-readable output
doc-approval submit --file contract.txt
doc-approval submit --text "Agreement between..."

# Machine-readable JSON
doc-approval submit --file contract.txt --json

# Health check
doc-approval health
doc-approval health --json

# Override runtime URL and workspace
doc-approval submit --base-url http://192.168.1.42:8787 --workspace my-workspace --text "..."
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
| `commands/submit.rs` | Execute + poll loop |
| `commands/health.rs` | `/healthz` check |
| `output.rs` | Human (colored) and JSON formatters |

## Phase 2 (not implemented)

SSE streaming and `doc-approval queue` when Traverse ships [#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527).
