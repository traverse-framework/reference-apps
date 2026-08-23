# loop (CLI)

**Runtime mode: embedded** — `loop-core-rs` + public `traverse-embedder`. No `traverse-cli serve` sidecar is required.

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
cargo test -p loop-cli
cargo run -p loop-cli -- health
cargo run -p loop-cli -- submit --text "Alex will send notes."
```

Override manifest: `LOOP_MANIFEST=manifests/loop/app.manifest.json`.
