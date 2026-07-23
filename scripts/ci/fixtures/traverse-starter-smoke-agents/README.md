# traverse-starter smoke agents

Digest-pinned **Traverse-published** example agents used by
`scripts/ci/prepare_embedded_smoke_bundle.sh` / `scripts/ci/embedded_smoke.sh`.

Provenance is recorded in `digests.json` (`provenance.ref` + per-agent
`traverse_source`). These binaries are copies of Traverse
`examples/traverse-starter/{validate,process,summarize}-agent` artifacts — not
App-Refs hand-built WASI stand-ins.

Refresh from a Traverse checkout that contains the real stdout-only agents:

```bash
export TRAVERSE_REPO=/path/to/Traverse   # main (post #795/#803/#805/#809)
bash scripts/ci/pin_traverse_starter_smoke_agents.sh
```

Prepare overlays these pinned digests onto `$TRAVERSE_REPO` and the synced web
bundle so CI can stay on an older Traverse tag while still exercising product
agent output shapes.
