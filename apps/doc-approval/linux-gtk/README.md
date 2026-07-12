# doc-approval (Linux GTK4)

Native Linux client for the `doc-approval` reference app. Uses shared `doc-approval-core-rs` for HTTP command dispatch and SSE app-state events.

Requires GTK4 + libadwaita system packages.

```bash
cd apps/doc-approval
cargo build -p doc-approval-gtk
cargo test -p doc-approval-core-rs
cargo run -p doc-approval-gtk
```
