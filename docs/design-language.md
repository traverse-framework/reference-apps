# Shared UI Design Language

Minimum design contract for all traverse-starter platform clients. This spec defines **information architecture and naming** — not pixels, colors, or spacing. Each platform implements these zones in its native idiom.

## Three Zones (fixed order)

Every client presents the same three zones, top to bottom:

### Zone 1 — Runtime Environment

| Element | Description |
|---|---|
| Runtime URL | Text display of the configured base URL |
| Runtime status | `Online` (green) / `Offline` (red) / `Checking` (animated) |
| Workspace | Workspace ID (e.g. `local-default`) |
| Capability ID | Capability being invoked (e.g. `traverse-starter.process`) |

### Zone 2 — Input

| Element | Description |
|---|---|
| Text input | Multi-line note/question field |
| Character count | Current length / soft limit |
| Submit action | Primary action to start workflow |
| Offline hint | Explanation when submit is disabled because runtime is offline |

### Zone 3 — Output

| State | Display |
|---|---|
| Idle | Empty-state placeholder |
| In progress | Loading / polling indicator |
| Succeeded | Structured runtime output fields (native widgets) |
| Failed | Error message from runtime/client |
| Trace | Expandable list of trace events (when available) |

## Output field names (runtime-owned)

The UI renders these fields exactly as the runtime provides them — never computed locally:

- `title`
- `tags`
- `noteType`
- `suggestedNextAction`
- `status`

## Platform idiom mapping (Zone 2 submit)

| Platform | Submit trigger |
|---|---|
| Web | Cmd+Enter / button click |
| iOS | Submit button in keyboard toolbar |
| macOS | ⌘↩ / toolbar button |
| Android | IME action / FAB |
| Windows | Ctrl+Enter / button |
| Linux | Ctrl+Enter / button |
| CLI | `--note` arg / stdin |

## Reference implementation

| Platform | Path | Status |
|---|---|---|
| Web (React) | `apps/traverse-starter/web-react/` | Shipped |
| trace-explorer | `apps/trace-explorer/web-react/` | Developer tool (trace-only UI) |
| iOS (SwiftUI) | `apps/traverse-starter/ios-swift/` | Shipped |
| macOS (SwiftUI + AppKit) | `apps/traverse-starter/macos-swift/` | Shipped |
| Android (Jetpack Compose) | `apps/traverse-starter/android-compose/` | Shipped |
| Windows (WinUI 3) | `apps/traverse-starter/windows-winui/` | Shipped |
| Linux (GTK4 + Rust) | `apps/traverse-starter/linux-gtk/` | Shipped |
| CLI (Rust) | `apps/traverse-starter/cli-rust/` | Shipped |

### doc-approval (Phase 1 submitter)

| Platform | Path | Status |
|---|---|---|
| Web (React) | `apps/doc-approval/web-react/` | Shipped |
| iOS (SwiftUI) | `apps/doc-approval/ios-swift/` | Shipped |
| macOS (SwiftUI + AppKit) | `apps/doc-approval/macos-swift/` | Shipped |
| Android (Jetpack Compose) | `apps/doc-approval/android-compose/` | Shipped |
| Windows (WinUI 3) | `apps/doc-approval/windows-winui/` | Shipped |
| Linux (GTK4 + Rust) | `apps/doc-approval/linux-gtk/` | Shipped |
| CLI (Rust) | `apps/doc-approval/cli-rust/` | Shipped |

New platform clients must link to this doc in their issue Definition of Done.

## Governance

- Native UI idioms are correct per platform — do not force web styling onto native clients
- Zone order and field names are **non-negotiable** for traverse-starter parity
- trace-explorer uses Zone 1 only (runtime strip) plus trace-specific lookup/timeline zones
