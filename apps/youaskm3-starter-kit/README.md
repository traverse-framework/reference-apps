# youaskm3 Traverse Starter Kit

This starter kit is a reference integration package for browser-hosted downstream apps that want to adopt Traverse without repo archaeology.

Canonical home: **`traverse-framework/reference-apps`** (`apps/youaskm3-starter-kit/`).

It is intentionally small:

- it points to the versioned Traverse consumer bundle
- it points to the browser-targeted consumer package in this repo
- it points to MCP consumption and compatibility validation docs in Traverse
- it leaves downstream UI and product behavior to the consuming app

## What It Is For

Use this starter kit as the first place a downstream app developer looks when wiring Traverse into a browser-hosted app such as `youaskm3`.

## Included References

- [Embedded getting started (this repo)](../../docs/getting-started-embedded.md) — WASM-once / UI-shell model on Web + Linux/CLI
- [Consumer bundle (Traverse)](https://github.com/traverse-framework/Traverse/blob/main/docs/app-consumable-consumer-bundle.md)
- [Starter kit guide (this repo)](../../docs/youaskm3-starter-kit.md)
- [Integration validation (Traverse)](https://github.com/traverse-framework/Traverse/blob/main/docs/youaskm3-integration-validation.md)
- [Compatibility suite (Traverse)](https://github.com/traverse-framework/Traverse/blob/main/docs/youaskm3-compatibility-conformance-suite.md)
- Local consumer package: [`apps/browser-consumer/`](../browser-consumer/)

## Supported Assumptions

- The consuming app is browser-hosted.
- The consuming app uses the published Traverse consumer bundle.
- The consuming app depends on the browser-targeted consumer package rather than Traverse internals.
- The consuming app validates paths using the documented commands in this repository and Traverse.

## Validation

```bash
bash scripts/ci/youaskm3_starter_kit_smoke.sh
```
