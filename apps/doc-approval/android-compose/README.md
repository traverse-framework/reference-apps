# doc-approval (Android Compose)

Native Android submitter client for the `doc-approval` reference app. Phase 1 uses HTTP polling via Ktor — same flow as `web-react`.

## Prerequisites

- **Android Studio Ladybug+** (or compatible AGP 8.7 / Kotlin 2.0)
- **Android emulator** API 26+ (or physical device on same network as runtime)
- **Traverse runtime** running on your host machine

```bash
git clone https://github.com/traverse-framework/Traverse.git /tmp/traverse
cd /tmp/traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

## Runtime URL configuration

Default base URL is `http://10.0.2.2:8787` — the Android emulator alias for host `127.0.0.1`.

1. Open the app → **Settings**
2. Set **Runtime URL** and **Workspace** (`local-default`)
3. Save (persisted via DataStore)

On a physical device, use your computer's LAN IP instead of `10.0.2.2`.

## Build and run

```bash
cd apps/doc-approval/android-compose
./gradlew :app:assembleDebug :app:testDebugUnitTest
```

Open the project in Android Studio and run on an API 26+ emulator.

## Architecture

| File | Role |
|---|---|
| `TraverseClient.kt` | Ktor HTTP client (execute, poll, trace, health) |
| `ExecutionViewModel.kt` | StateFlow state machine: idle → loading → polling → done |
| `ui/MainScreen.kt` | Compose UI — runtime strip, document input, analysis output |
| `ui/SettingsScreen.kt` | Runtime URL + workspace |
| `SettingsRepository.kt` | DataStore persistence |

The UI renders runtime-provided output fields only (`docType`, `parties`, `amounts`, `confidence`, `recommendation`).

## Phase 2 (not implemented)

Replace polling with Ktor SSE when Traverse ships [#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527).

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
