# trace-explorer (Web React)

**Runtime mode: Embedded** — uses the public `embedded-trace-api/1.0.0` companion on `traverse-embedder-web` (`trace.list` / `trace.get`). No `traverse-cli serve` sidecar.

## Usage

1. From repo root: `npm install && npm run dev -w apps/trace-explorer/web-react`
2. Open the app — it lists safe local traces from the in-process host
3. Click a trace to view safe detail (no raw payloads)

To populate traces in a real session, run an embedded product shell (e.g. traverse-starter) that shares the same host, or inject `EmbedderTestDouble` in tests.

## Tests

```bash
npm run test -w apps/trace-explorer/web-react
```

Tests use `EmbedderTestDouble` only — no fake business fields in the UI.

See [docs/design-language.md](../../../docs/design-language.md) for shared UI zones.
