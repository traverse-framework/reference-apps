# meeting-notes (Android Compose)

**Runtime mode: Embedded** - public Kotlin `TraverseEmbedder` (`dev.traverse.embedder`) with digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` sidecar is required.

Native Android client for the `meeting-notes` reference app.

## Prerequisites

- Android Studio Ladybug+ (or compatible AGP 8.7 / Kotlin 2.0)
- Android emulator API 28+ (or physical device)
- Traverse checkout with the Kotlin embedder package and certified runtime artifact:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_android_meeting_notes_bundle.sh
```

`settings.gradle.kts` composites `$TRAVERSE_REPO/packages/kotlin/TraverseEmbedder` as `:traverse-embedder`.

## Bundle configuration

Assets live under `app/src/main/assets/bundles/meeting-notes/` (including `runtime/runtime.wasm` + `runtime-release.json` after sync). The app copies them into `filesDir` on launch.

Settings -> Workspace only (no sidecar URL). Default workspace is `local-default`.

## Build and test

```bash
export TRAVERSE_REPO=/path/to/Traverse
cd apps/meeting-notes/android-compose
./gradlew test
./gradlew :app:assembleDebug
```

Unit tests inject `InMemoryTraverseEmbedder` via `InMemoryMeetingNotesHost`; fixtures use only the runtime-owned `MeetingNotesOutput` fields.

## Architecture

| File | Role |
|---|---|
| `EmbeddedHost.kt` | Production + in-memory embedded hosts |
| `ExecutionViewModel.kt` | Submit transcript -> render runtime-owned output |
| `BundleAssets.kt` | Materialize asset bundle into filesDir |
| `ui/MainScreen.kt` | Embedded runtime status, transcript input, output, trace |

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md). Zone 1 shows **Embedded** runtime mode.
