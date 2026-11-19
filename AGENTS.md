# App-References — Agent Coordination

This repo is **UI-only**; canonical agent instructions (scope, structure, stack, commands, style, runtime setup, workflow) live in [CLAUDE.md](CLAUDE.md). This file holds only multi-tool coordination and curated blocker context, per `traverse-framework/.github` `docs/ai-agent-hardening.md`. Platform shipping status lives in README.md and on [Project 2](https://github.com/orgs/traverse-framework/projects/2) — never snapshot it here.

**Backlog rule:** tickets are GitHub Issues in this repo, added to Project 2, with the full Spec + DoD in the issue body. See [`docs/ticket-standard.md`](docs/ticket-standard.md). Older Project 2 draft items stay as history.

### Ready to claim (query live board)

```bash
gh project item-list 2 --owner traverse-framework --format json --limit 300 \
  --jq '.items[] | select(.status == "Ready" and .content.type == "Issue") | {number: .content.number, title: .content.title}'
```

### Start plan (demo gaps → tickets)

| Ticket ID | Status | Start |
|---|---|---|
| `remove-sidecar-paths` | **Done** (#206) | Sidecar paths removed from primary shells |
| `meeting-notes-multi-os` | **Done** (#208) | Web + Linux GTK + CLI embedded |
| `native-ci-android-gtk-required` | **Done** (#209) | Android/GTK nightly required |
| `phase2-sidecar-nightly` | Future | Defer — low demo value |
| `embed-trace-explorer` | **Done** (#225) | Embedded Trace API in Trace Explorer web |
| `registry-ref-starter-process` | **Done** (#224) | Process component uses `registry_ref` |
| `registry-ref-full-kit-cutover` | **Done** (#235) | All six primary components use `registry_ref` |
| `meeting-notes-wave2-os-ports` | **Done** (#236) | iOS + macOS + Windows + Android meeting-notes embeds |
| `consume-product-wasm-agents` | **Done** (#227) | Digest-pinned Traverse-published starter agents |
| `llm-mcp-reference-apps-plan` | **Done** (#238) | LLM MCP façades plan + scaffold (`apps/llm-mcp-reference/`) |
| `llm-mcp-meeting-notes-workflow` | **Done** (#239) | Meeting-notes MCP tool-sequence runbook |
| `llm-mcp-cursor-live-smoke` | **Done** (#240) | Cursor MCP Mode A stdio evidence |
| `llm-mcp-claude-live-smoke` | **Done** (#241) | Claude Desktop/Code MCP Mode A evidence |
| `kit-runner-persona-docs` | **Done** (#273) | Persona runbook + embedded onboarding |
| `new-app-author-e2e` | **Done** (#275) | CLI `app new` → App-Refs layout + Web host rewrite |
| `fix-nightly-native-macos-windows` | **Done** (#277) | Swift 6 Sendable mappers + WinUI test compile of PresentationMapper |
| `llm-mcp-mode-a-spec119-scaffold` | **Done** (#271) | Spec 119 consumer scaffold (fail-closed); live kit execute stays `llm-mcp-traverse-starter-catalog` |
| `llm-mcp-traverse-starter-catalog` | **Done** | Mode A live cutover after Traverse [#1241](https://github.com/traverse-framework/Traverse/issues/1241)/[#1252](https://github.com/traverse-framework/Traverse/pull/1252); evidence under `apps/llm-mcp-reference/` |
| `loop-wf1-registry-deps` | **Done** (#263) | Digest inventory in `docs/loop-registry-deps.md` |
| `loop-wf1-multi-os` | **Done** (#265) | `apps/loop/` WF1 × 7 OS; compose via `registry_ref` |
| `retire-registry-ref-materialize` | **Done** (#267) | Phase A gate; host cutover → Future `retire-registry-ref-materialize-hosts` |
| `retire-registry-ref-materialize-hosts` | **Future** | Full materialize delete after BundleEmbedder + Spec 107 |
| `meeting-notes-remaining-natives` | **Done** (#236) | Shipped via `meeting-notes-wave2-os-ports` |
| `llm-mcp-embedded-host` | **Future** | Scaffold Done (#268); Mode B host CLI on Traverse Project 1 ticket `implement-mode-b-embedded-mcp-host` (issue #1242) — not active until Mode A unlock progresses |
| `two-app-reuse-contract` | **Done** (#285) | Pin `meeting-notes.process` 1.3.2 for meeting-notes + loop |
| `two-app-reuse-execute` | **Done** (#286) | Align pins + wasmtime evidence |
| `two-app-reuse-execute-ci` | **Done** (#287) | Fixture-only evidence (no Traverse core examples) |
| `pin-ci-traverse-0-10` | **Done** (#292) | CI / embedder / runtime.wasm → Traverse v0.10.0 |
| `llm-mcp-0-10-live-cutover` | **Done** (absorbed) | Mode A → `llm-mcp-traverse-starter-catalog`; Mode B → `llm-mcp-embedded-host` Future; pin already #292 |
| `two-app-reuse-host-execute` | **Blocked** | #1240/#1255 fixed on Traverse **main** (`ff50bbc`); App-Refs pin **v0.10.0** still fails (`registered artifact execution failed`). Need a Traverse release tag containing #1255, then pin bump |
| `two-app-reuse-lifecycle` | **Done** (#283) | Fixture pin-flip + documented deprecation for meeting-notes + loop (not BundleEmbedder; not production release-train) |

Full gap table + wave notes: [`docs/production-reference-plan.md`](docs/production-reference-plan.md).

### Flip rules (native embeds)

Upstream flip conditions are met (Traverse #750/#751/#647 closed). Embeds are **Done**. Return any platform to Blocked only if Traverse withdraws the certified `runtime/runtime.wasm` artifact or reopens those upstream issues.

## Multi-Agent Coordination

Several coding tools work here in parallel. **Claim before you code: one issue = one agent.** Claim and release with the shared scripts, vendored from `traverse-framework/.github` v1.4.0. The Project 2 ids live in `.agent-claim.json`.

```bash
scripts/agent/claim.sh <issue> <claude|codex|cursor> --dry-run   # check only
scripts/agent/claim.sh <issue> <claude|codex|cursor>             # claim
scripts/agent/release.sh <issue> <Ready|Blocked|Done>            # release after merge
```

`claim.sh` changes nothing unless the issue is open, its Project 2 status is Ready, it carries no `agent:*` label, and no `*/issue-<N>-*` branch or open PR from any tool exists. If it refuses, pick another issue; never "help" a claimed one. Work on `<tool>/issue-<N>-*`. The `agent:*` label is the claim marker. The Project 2 **Agent** field is no longer used.

## Board hygiene

When a platform client (or other major slice) ships, update all doc touchpoints in one pass:

1. **Project 2**: release the issue with `release.sh <N> Done`
2. **`README.md`**: update the Platform clients table; remove the client from **What's Blocked** if it's no longer blocked
3. **`docs/design-language.md`**: add or update the row in the Reference implementation table

Don't leave shipped platforms listed as "in progress" or "blocked" in any doc.

## Creating tickets

```bash
gh issue create --repo traverse-framework/reference-apps --title '...' --body-file ticket.md   # Spec + DoD per docs/ticket-standard.md
gh project item-add 2 --owner traverse-framework --url <issue-url>                             # then set Status
```
