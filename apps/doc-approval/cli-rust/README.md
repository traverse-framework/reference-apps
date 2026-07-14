# doc-approval (Rust CLI)

Terminal client for the `doc-approval` reference app. Uses `doc-approval-core-rs` with the public **`traverse-embedder`** SDK. No `traverse-cli serve` sidecar.

**Note:** production bundle init requires `manifests/doc-approval/` ([#112](https://github.com/traverse-framework/reference-apps/issues/112)). Until then, health/submit report Unavailable; unit tests use `EmbedderTestDouble`.

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
| `DOC_APPROVAL_MANIFEST` | Path to `app.manifest.json` when #112 lands |
