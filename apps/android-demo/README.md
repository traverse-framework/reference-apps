# Traverse Android Demo

Checked-in Android (Compose) demo for Traverse expedition planning.

Canonical home: **`traverse-framework/reference-apps`** (`apps/android-demo/`).

What it does:

- renders one approved expedition flow
- shows ordered runtime state updates
- shows the final trace summary and output panel
- assumes the runtime exists outside the app process

Fixture-driven rendering uses `app/src/main/assets/expedition-runtime-session.json`.

## Build (machine with Android SDK)

```bash
cd apps/android-demo
./gradlew :app:assembleDebug
```

## Validation

```bash
bash scripts/ci/android_demo_smoke.sh
```
