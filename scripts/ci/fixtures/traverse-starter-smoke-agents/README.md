# traverse-starter smoke agents

Deterministic WASI command modules used only by `scripts/ci/embedded_smoke.sh`.
Each writes fixed JSON matching the public capability contracts (validate / process / summarize).

Rebuild: `node scripts/ci/fixtures/build_starter_smoke_agents.mjs` (requires `wabt`).

These are **not** UI business logic — they stand in for Traverse example agents until
those ship non-stub WASM. Digests are applied to the smoke bundle at prepare time.
