# App-References Constitution

## Core Principles

### I. UI Is a Rendering Layer
This repo is a UI-only reference implementation. The React layer must not own business decisions. All structured output — tags, note type, title, suggested next action, workflow status — must come from the Traverse runtime. The UI renders, sorts, filters, and displays runtime-provided data only. Any logic that computes a business field in the UI is a constitution violation.

### II. Architecture Boundary Is Non-Negotiable
The boundary between this repo and Traverse is explicit and enforced:
- This repo: React components, event subscriptions, UI state, configuration, and smoke tests
- Traverse: business capabilities, workflow execution, event emission, structured output

Code, imports, and abstractions must not cross this boundary in either direction. Importing private Traverse internals into this repo is a constitution violation. Pushing business logic from Traverse into this repo is equally a violation.

### III. Runtime-Driven UI State
UI state must be driven by events from the Traverse runtime, not by locally computed state or mock data. The event subscription boundary is explicit and must use only public Traverse runtime interfaces. Hidden local state that mirrors what the runtime should provide is a constitution violation.

### IV. No Fake Runtime Behavior
Phase 1 is deterministic and does not require live AI access. It does require a real local Traverse runtime or an explicit, documented stub. Fake workflow registration, fake event emission, and mock runtime responses embedded in application code are constitution violations. Test doubles used in unit tests are acceptable when clearly scoped to tests.

### V. Phase Gate Discipline
Phase 2 (app validation and registration via Traverse CLI) is explicitly blocked until the Traverse public CLI surface (`traverse-cli app validate`, `traverse-cli app register`) exists in a released or pinned build. Do not implement a workaround, HTTP registration endpoint, or service registry as a substitute. Document the dependency clearly and keep the Phase 2 ticket blocked.

### VI. Traceability
Every meaningful change must be tracked through a GitHub issue, a Project 2 item, and a pull request. These three artifacts are the minimum traceability model.

### VII. Quality Gates Block Merge
A change must not merge when any of the following are true:
- TypeScript type errors exist
- ESLint violations exist
- Unit tests fail
- Required coverage for non-trivial UI logic falls below threshold
- PR hygiene check fails (missing required sections)
- The change lacks the required traceability artifacts

### VIII. Agent Coordination
When two agents work in parallel, claim before you code. Check for `agent:claude` label and `claude/issue-NNN-*` branch before starting any issue. If either exists, stop and pick a different ticket. See `AGENTS.md` for the full pre-flight and claim sequence.

## Non-Functional Requirements

- **Determinism**: same runtime events must produce the same rendered output
- **Testability**: non-trivial UI logic must be designed for full automated verification
- **Maintainability**: component boundaries must support long-term evolution without hidden coupling to runtime internals
- **Portability**: the UI shell must remain deployable as a standard web app without coupling to a specific Traverse host or infrastructure vendor
- **Reproducibility**: builds, tests, and CI gates must be reproducible from pinned inputs and documented commands

## Development Workflow

1. Confirm the change belongs in the UI layer (not in Traverse)
2. Claim a Ready Project 2 issue and run pre-flight checks (`AGENTS.md`)
3. Implement the smallest change that satisfies the issue and the architecture boundary
4. Verify all CI gates pass locally before pushing
5. Open a PR with the required sections (`docs/ticket-standard.md`)

## Governance

This constitution overrides convenience-based implementation decisions and hidden coupling.

All reviews must check for:
- Business logic leaked into the UI
- Private Traverse internals imported
- Fake runtime behavior in application code
- Missing traceability artifacts
- Phase 2 work started without the required Traverse CLI surface

Amendments require documenting the rule being changed, the reason, and the migration impact.

**Version**: 1.0.0 | **Ratified**: 2026-06-27
