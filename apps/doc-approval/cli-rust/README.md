# doc-approval (Rust CLI)

**Runtime mode: embedded** — `doc-approval-core-rs` + public `traverse-embedder`. No `traverse-cli serve` sidecar is required.

Terminal client for the `doc-approval` reference app.

**Note:** production bundle init uses `manifests/doc-approval/`. Unit tests use `EmbedderTestDouble`.

## Build

```bash
cd apps/doc-approval
cargo test -p doc-approval-cli -p doc-approval-core-rs
cargo install --path cli-rust
```

## Usage

```bash
doc-approval submit --text "Invoice …"
doc-approval health --json
```

| Variable | Purpose |
|---|---|
| `DOC_APPROVAL_MANIFEST` | Path to `app.manifest.json` |
