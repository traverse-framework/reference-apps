# TraverseCore

Shared Swift package for traverse-starter **iOS** and **macOS** clients.

- `TraverseClient` — health, `sendCommand`, SSE `subscribeAppEvents`, fetchTrace
- `AppStateViewModel` — `@MainActor ObservableObject` mapping runtime SSE payloads
- `TraverseOutput` / `TraverseCommand` — public types + parsers
- `ServerDiscovery` — reads `.traverse/server.json` on macOS only

```bash
cd apps/traverse-starter/TraverseCore
swift test
```

No UIKit / AppKit imports. Platforms: iOS 17+, macOS 14+.
