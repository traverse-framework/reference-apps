# meeting-notes (CLI)

**Runtime mode: embedded** — `meeting-notes-core-rs` + public `traverse-embedder`. No `traverse-cli serve` sidecar is required.

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
cargo test -p meeting-notes-cli
cargo run -p meeting-notes-cli -- health
cargo run -p meeting-notes-cli -- submit --text "Alex will send notes."
```

Override manifest: `MEETING_NOTES_MANIFEST=manifests/meeting-notes/app.manifest.json`.
