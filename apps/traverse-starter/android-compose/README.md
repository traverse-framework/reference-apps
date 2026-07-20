# traverse-starter (Android Compose)

**Runtime mode: embedded** — public Kotlin `TraverseEmbedder` (`dev.traverse.embedder`) with digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` sidecar is required.

Native Android client for the `traverse-starter` reference app.

## Prerequisites

- **Android Studio Ladybug+** (or compatible AGP 8.7 / Kotlin 2.0)
- **Android emulator** API 28+ (or physical device)
- **Traverse checkout** with the Kotlin embedder package and certified runtime artifact:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_android_starter_bundle.sh
```

`settings.gradle.kts` composites `$TRAVERSE_REPO/packages/kotlin/TraverseEmbedder` as `:traverse-embedder`.

## Bundle configuration

Assets live under `app/src/main/assets/bundles/traverse-starter/` (including `runtime/runtime.wasm` + `runtime-release.json`). The app copies them into `filesDir` on launch.

Settings → **Workspace** only (no sidecar URL).

## Build and test

```bash
export TRAVERSE_REPO=/path/to/Traverse
cd apps/traverse-starter/android-compose
./gradlew test
./gradlew :app:assembleDebug
```

Unit tests inject `InMemoryTraverseEmbedder` via `InMemoryStarterHost` — they never compute business fields in the UI.

## Architecture

| File | Role |
|---|---|
| `EmbeddedHost.kt` | Production + in-memory embedded hosts |
| `ExecutionViewModel.kt` | Submit note → render runtime-owned output |
| `BundleAssets.kt` | Materialize asset bundle into filesDir |
| `ui/MainScreen.kt` | Zones 1–3; Zone 1 shows Embedded / Ready |

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md). Zone 1 shows **Embedded** runtime mode.
