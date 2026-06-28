# Quality Standards

This document defines the operational quality standards for App-References.

These standards work together with the constitution. If there is a conflict, the constitution takes precedence.

## Core Rule

Code is not considered mergeable unless it is:

- aligned with the UI-only architecture boundary
- validated by the required automated checks
- maintainable at production quality
- free of leaked business logic or private Traverse internals

## Engineering Standards

All in-scope code must meet these standards:

- Clear component and hook boundaries
- No business decisions in the rendering layer
- Deterministic rendering for the same runtime-provided inputs
- Actionable error and loading states driven by runtime events
- Testability by design for non-trivial UI logic
- No hidden coupling to Traverse internals
- No fake runtime behavior in application code

## Required Validation Gates

The default validation flow includes:

- TypeScript type check (`npm run typecheck`)
- ESLint (`npm run lint`)
- Unit tests (`npm run test`)
- Coverage gate for non-trivial UI logic (`npm run test:coverage`)
- Repository structure check (`bash scripts/ci/repository_checks.sh`)
- PR body validation (`bash scripts/ci/pr_body_check.sh`)

## Coverage Standard

Required coverage for non-trivial UI logic:

- Event parsing and transformation
- UI state machine (loading, progress, error, final)
- Any hook that computes derived state from runtime events

Coverage gate implementation:

- script: `scripts/ci/coverage_gate.sh`
- threshold: defined in `scripts/ci/coverage_gate.sh`

The coverage gate is merge-safe before non-trivial logic exists — it passes when no covered targets are configured.

## Reproducibility Standard

Build and validation flows must be reproducible from pinned inputs:

- pinned Node.js version (`.nvmrc` or `engines` in `package.json`)
- pinned dependencies (`package-lock.json` or equivalent)
- documented commands (this doc and `CLAUDE.md`)
- CI using the same commands expected locally

## Merge Blocking Conditions

A change must not merge when any of the following are true:

- TypeScript type errors exist
- ESLint violations exist
- Unit tests fail
- Required coverage threshold is not met
- Repository structure check fails
- PR body is missing required sections
- Business logic is implemented in the UI layer
- Private Traverse internals are imported
- Fake runtime behavior exists in application code
- The change lacks a GitHub issue + Project 2 item + PR

## Nightly CI Gate

A nightly job runs the Phase 1 smoke test independently of any PR activity.

**Schedule**: daily at 06:00 UTC (`.github/workflows/nightly.yml`)

**What it validates**:
- Phase 1 end-to-end smoke (`scripts/ci/phase1_smoke.sh`)
- Repository structure checks (`scripts/ci/repository_checks.sh`)
- TypeScript, lint, and test suite

**SLA**: any nightly failure must be investigated within 24 hours. A broken nightly sitting more than 24 hours is a P1 issue.

**Manual trigger**: the workflow supports `workflow_dispatch`.

## Problem Handling Rule

When active work reveals a problem:

- must-fix issues (correctness, mergeability, governance) must be resolved in the current PR
- non-blocking follow-ups must be captured as `future` tickets instead of being left implicit
