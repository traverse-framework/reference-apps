# doc-approval (Rust CLI)

Terminal client for the `doc-approval` reference app. Uses shared `doc-approval-core-rs` for HTTP command dispatch and SSE app-state events.

```bash
cd apps/doc-approval
cargo build -p doc-approval-cli --release
cargo test -p doc-approval-cli -p doc-approval-core-rs
cargo install --path cli-rust
```
