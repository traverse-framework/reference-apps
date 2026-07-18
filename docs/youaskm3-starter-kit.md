# youaskm3 Starter Kit and Integration Guide

This document is the integration guide for browser-hosted downstream apps such as `youaskm3`.

It pairs with the reference starter kit at [`apps/youaskm3-starter-kit/README.md`](../apps/youaskm3-starter-kit/README.md).

This youaskm3 starter kit and integration guide is the canonical browser-hosted adoption path for the downstream app (source of truth: `traverse-framework/reference-apps`).

## Goal

Give a downstream app team one clear adoption path for Traverse without forcing them to reverse-engineer either repository.

For the **embedded reference-app** walkthrough (WASM once, UI shells everywhere — Web / Linux / CLI), start with [`getting-started-embedded.md`](getting-started-embedded.md). This youaskm3 kit is the **browser consumer-bundle** path for downstream hosts.

## What to Install

Downstream apps should adopt the versioned Traverse consumer bundle and the browser-targeted consumer package:

- Traverse consumer-bundle docs: [app-consumable-consumer-bundle.md](https://github.com/traverse-framework/Traverse/blob/main/docs/app-consumable-consumer-bundle.md)
- Local façade: [`apps/browser-consumer/`](../apps/browser-consumer/)

## Setup

1. Read the Traverse [quickstart](https://github.com/traverse-framework/Traverse/blob/main/quickstart.md).
2. Review the app-consumable consumer bundle.
3. Use [`apps/browser-consumer/`](../apps/browser-consumer/) from this repository.
4. Run the offline starter-kit smoke below; optionally run live adapter validation when a Traverse checkout is available.

## Validation

Offline (always available in this repo):

```bash
bash scripts/ci/youaskm3_starter_kit_smoke.sh
bash scripts/ci/react_demo_smoke.sh
bash scripts/ci/browser_consumer_package_smoke.sh  # requires TRAVERSE_REPO for live path
```

Live adapter path (requires `TRAVERSE_REPO`):

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/react_demo_live_adapter_smoke.sh
bash scripts/ci/browser_consumer_package_smoke.sh
```

## Known Limits

This guide does not promise:

- custom downstream app UX
- full auth hardening
- multi-tenant deployment guarantees
- direct Traverse source checkout coupling for production apps
