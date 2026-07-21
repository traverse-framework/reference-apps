# meeting-notes (Linux GTK)

**Runtime mode: embedded** — `meeting-notes-core-rs` + public `traverse-embedder`. No `traverse-cli serve` sidecar is required.

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
cargo test -p meeting-notes-gtk
cargo run -p meeting-notes-gtk
```

Preferences → optional manifest path override (`MEETING_NOTES_MANIFEST`).
