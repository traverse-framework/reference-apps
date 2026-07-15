# doc-approval (Linux GTK4)

Native Linux client for `doc-approval`. Uses `doc-approval-core-rs` with **`traverse-embedder`** (Phase 3). No sidecar URL.

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
