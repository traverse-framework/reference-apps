# doc-approval (Linux GTK4)

**Runtime mode: embedded** — `doc-approval-core-rs` + public `traverse-embedder`. No `traverse-cli serve` sidecar is required.

Native Linux client for `doc-approval`.

**Note:** Zone 1 shows Embedded / Ready when `manifests/doc-approval/` resolves (or `DOC_APPROVAL_MANIFEST`).

## Prerequisites

```bash
sudo apt install libgtk-4-dev libadwaita-1-dev
export TRAVERSE_REPO=/path/to/Traverse   # sibling checkout with traverse-embedder
```

## Build

```bash
cd apps/doc-approval
cargo test -p doc-approval-core-rs
cargo run -p doc-approval-gtk
```

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
