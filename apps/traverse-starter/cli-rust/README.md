# traverse-starter (Rust CLI)

Terminal client for the `traverse-starter` reference app. Uses the shared `traverse-core-rs` crate with the public **`traverse-embedder`** SDK (Phase 3 embedded runtime). No `traverse-cli serve` sidecar is required.

## Prerequisites

- **Rust 1.78+** via [rustup](https://rustup.rs/)
- **Traverse checkout** with `traverse-embedder` and example WASM:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh   # from App-References root
```

## Build and install

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

# Embedded runtime readiness
traverse-starter health
traverse-starter health --json
```

Environment variables:

| Variable | Default |
|---|---|
| `TRAVERSE_STARTER_MANIFEST` | auto-discover `manifests/traverse-starter/app.manifest.json` |

## Architecture

| File | Role |
|---|---|
| `../traverse-core-rs` | Shared `EmbeddedRuntime` over `traverse-embedder` |
| `client.rs` | Re-exports embedded host types |
| `commands/run.rs` | Submit note to `traverse-starter.pipeline` |
| `commands/health.rs` | Embedded init readiness |
| `output.rs` | Human (colored) and JSON formatters |
