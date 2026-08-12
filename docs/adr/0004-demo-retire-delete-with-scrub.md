# ADR-0004: Retire Demos by Delete + Docs/CI Scrub

- Status: Accepted
- Date: 2026-08-11
- Governing spec: `004-demo-upgrade-or-retire`

## Context

Expedition demos and starter kits can lag primary refs and leave the tree looking half-updated. Soft deprecation without removal tends to create junk drawers.

## Decision

Classify each demo as `upgrade` or `retire`. Retirements delete the app in a Project 2 ticket/PR that also removes CI jobs and updates README (including a **Retired demos** note), design-language, and getting-started links.

## Consequences

- Inventory ticket must finish before retire/upgrade tickets are `Ready`.
- Removals are intentional and documented; recovery is via git history.
- No long-lived `archive/` folder for demos.

## Alternatives considered

- Archive folder / separate archive repo — rejected; becomes a second junk drawer.
- CI-fail only without deletion — rejected; half-products remain in `apps/`.
