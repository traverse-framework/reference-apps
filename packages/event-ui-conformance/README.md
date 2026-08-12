# event-ui-conformance

Shared TypeScript helpers for Specs 001/002:

- Pure `mapPresentationState` → `idle|loading|loaded|blocked|ended|error`
- `mapCapabilityProgress` / `activeCapabilityId` from public embedder events
- Loaders for language-agnostic fixtures under `fixtures/event-ui-conformance/`

Consumer guide: [`docs/event-ui-conformance-harness.md`](../../docs/event-ui-conformance-harness.md).

```bash
npm run test -w event-ui-conformance
npm run typecheck -w event-ui-conformance
```
