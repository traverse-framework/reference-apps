# Adopted Traverse platform clients

This repository is the **canonical home** for checked-in application UI, platform client demos, and starter/reference source previously maintained under Traverse `apps/`.

## Primary vs secondary (maintenance bar)

| Tier | Apps | Bar |
|---|---|---|
| **Primary product shells** | `traverse-starter`, `doc-approval` (all platforms); `meeting-notes` (web today → multi-OS in [#179](https://github.com/traverse-framework/reference-apps/issues/179)) | Embedded-first; design-language zones; public embedders; merge-blocking `embedded_smoke` for Linux Web+CLI |
| **Secondary / adopted** | `react-demo`, `android-demo`, `macos-demo`, `browser-consumer`, `youaskm3-starter-kit` | Lighter maintenance; offline/live smoke scripts below; **not** hard-fail slices of `embedded_smoke.sh` |
| **Debugger exception** | `trace-explorer` | Named HTTP exception ([#183](https://github.com/traverse-framework/reference-apps/issues/183)) — not a product shell to copy |

Do **not** copy Expedition demo / starter-kit patterns into primary shells without caveats. Shipping guide: [`production-playbook.md`](production-playbook.md).

Ownership boundary (Traverse [#703](https://github.com/traverse-framework/Traverse/issues/703)):

| Former Traverse path | Owner | Destination here |
|---|---|---|
| `apps/android-demo/` | Reference Apps | [`apps/android-demo/`](../apps/android-demo/) |
| `apps/browser-consumer/` | Reference Apps | [`apps/browser-consumer/`](../apps/browser-consumer/) |
| `apps/macos-demo/` | Reference Apps | [`apps/macos-demo/`](../apps/macos-demo/) |
| `apps/react-demo/` | Reference Apps | [`apps/react-demo/`](../apps/react-demo/) |
| `apps/youaskm3-starter-kit/` | Reference Apps | [`apps/youaskm3-starter-kit/`](../apps/youaskm3-starter-kit/) |
| Runtime fixtures / manifests | Traverse | `examples/` in Traverse (not adopted) |

Shared fixture for native demos: [`fixtures/expedition-runtime-session.json`](../fixtures/expedition-runtime-session.json).

## Validation commands (secondary)

| Artifact | Command |
|---|---|
| Android demo | `bash scripts/ci/android_demo_smoke.sh` |
| macOS demo | `bash scripts/ci/macos_demo_smoke.sh` |
| React demo | `bash scripts/ci/react_demo_smoke.sh` |
| youaskm3 starter | `bash scripts/ci/youaskm3_starter_kit_smoke.sh` |
| React live adapter | `TRAVERSE_REPO=… bash scripts/ci/react_demo_live_adapter_smoke.sh` |
| Browser consumer live | `TRAVERSE_REPO=… bash scripts/ci/browser_consumer_package_smoke.sh` |

All adopted artifacts use public Traverse surfaces (browser adapter CLI, published consumer-bundle docs). No private runtime crate imports.
