# Traverse macOS Demo

Checked-in native SwiftUI demo for Traverse expedition planning.

Canonical home: **`traverse-framework/reference-apps`** (`apps/macos-demo/`).

What it does:

- renders one approved expedition flow
- shows ordered runtime state updates
- shows the final trace summary and output panel
- keeps the runtime separate from the app process

Fixture source: [`fixtures/expedition-runtime-session.json`](../../fixtures/expedition-runtime-session.json) (run the app from the repository root so the relative path resolves).

## Run (full Xcode)

```bash
open apps/macos-demo/Package.swift
# run TraverseMacOSDemoApp
```

## Validation

```bash
bash scripts/ci/macos_demo_smoke.sh
```
