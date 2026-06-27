# App-References

Reference application implementations for the Traverse framework.

**This repo is UI-only.** Traverse runtime and business logic live outside this repo.

## traverse-starter

A reference React UI that demonstrates integrating with the Traverse runtime: starting workflows, receiving events, and rendering runtime-provided structured output without owning business logic.

See [docs/traverse-starter-plan.md](docs/traverse-starter-plan.md) for the full plan, architecture boundary, phase breakdown, and ticket definitions.

## Development

See the plan doc for:
- Phase 1 scope (UI shell + runtime event client + smoke test)
- Phase 2 scope (app validation/registration via Traverse CLI — currently blocked)
- Traverse dependency model (`TRAVERSE_REPO` override for framework development)
