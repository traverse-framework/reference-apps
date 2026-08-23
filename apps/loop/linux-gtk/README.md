# loop (Linux GTK)

**Runtime mode: embedded** — `loop-core-rs` + public `traverse-embedder`. No `traverse-cli serve` sidecar is required.

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
cargo test -p loop-gtk
cargo run -p loop-gtk
```

Preferences → optional manifest path override (`LOOP_MANIFEST`).
