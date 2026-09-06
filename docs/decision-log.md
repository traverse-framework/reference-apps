# Decision Log

Append-only record of design decisions for App-References. Newest sessions at the bottom.

---

## 2026-08-11 — Event parity + Loop ref app

**Context:** Traverse and the registry changed substantially. Goal: verify every reference app can subscribe to runtime state-machine events and capability events for correct UI, then add Loop (from `loop-capability-package-v2`) as a first-class multi-OS reference app — with no stale leftovers in the tree.

**Governing artifacts (Approved / Accepted):**
- Specs: [`specs/001`](specs/001-ui-event-state-conformance/spec.md), [`002`](specs/002-capability-event-ui-subscription/spec.md), [`003`](specs/003-loop-wf1-reference-app/spec.md), [`004`](specs/004-demo-upgrade-or-retire/spec.md)
- ADRs: [`adr/0001`](adr/0001-event-fixture-harness-first.md)–[`0005`](adr/0005-platform-bar-loop-all-os.md)

**Source package:** `/Users/enricopiovesan/Downloads/loop-capability-package-v2 (1).zip` (contracts + product/workflow docs; no WASM binaries).

### Workstream sequencing

**Question:** What should this workstream optimize for first?

**Options considered:**
- Prove subscriptions on existing apps only — pros: fastest signal; cons: no Loop demo
- Build Loop as the proving vehicle — pros: end-to-end product proof; cons: contracts-only package; larger before embeds are verified
- Split: subscription matrix first, then minimal Loop slice — pros: de-risks platform contract then lands demo; cons: two phases

**Recommendation:** Split (subscription matrix → Loop).

**Decision:** Split — existing-app subscription matrix first, then a thin Loop slice.

**Why:** Registry/runtime churn usually breaks subscription shapes first; prove that on apps that already embed before product work.

### Loop workflow slice

**Question:** For Phase 2, which Loop slice should be the first demo?

**Options considered:**
- WF1 Ingest & Extract — pros: closest to meeting-notes; clear UI states; cons: not the product hero
- WF3 Follow-up & Nudge — pros: matches positioning; cons: heavier (quiet hours, budgets)
- Single-capability smoke — pros: fastest; cons: weak product demo

**Recommendation:** WF1.

**Decision:** WF1 Ingest & Extract first; WF3 deferred to a later wave.

**Why:** Proves state machine + multi-capability events without boiling the ocean.

### Where Loop UI lives

**Question:** Where should the Loop UI live?

**Options considered:**
- New `apps/loop/` (web first, then other OS) — pros: clean product story; cons: more scaffolding
- Extend `meeting-notes` — pros: reuses hosts/CI; cons: muddies product identity
- Web-only Loop shell — pros: smallest; cons: fails all-OS ref-app bar

**Recommendation:** New `apps/loop/` with web as first shipping target inside that app.

**Decision:** New `apps/loop/` reference app. Refined by later decisions: Loop must meet the full seven-OS bar (not permanently web-first), and no ref app may be left outdated.

**Why:** User requires all ref apps to be real ref apps at end of day — no second-class or stale surfaces.

### Completeness bar

**Question:** Implied by “all ref apps updated, nothing left behind.”

**Decision:** Full reference-app parity — existing primaries updated to the new event contract; Loop is first-class multi-OS; demos either match or are retired on purpose.

**Why:** Explicit user requirement against leftover / half-updated apps.

### Delivery sequencing under that bar

**Question:** How should we sequence parity work?

**Options considered:**
- Existing apps first, then Loop at full multi-OS bar — pros: Loop not built on broken events; cons: Loop lands later
- Parallel waves — pros: faster calendar; cons: coordination / moving API risk
- Platform waves (all apps on web, then natives) — pros: one embedder fix helps all; cons: easier to leave natives incomplete

**Recommendation:** Existing apps first, then Loop.

**Decision:** Phase 1 = existing primary clients; Phase 2 = Loop at full multi-OS bar.

**Why:** Fix the shared subscription contract before standing up a new product ref on it.

### Loop capability binaries

**Question:** Where do Loop capability binaries come from? (Zip is contracts-only.)

**Options considered:**
- Consume from Traverse registry when published — pros: real ref pattern; cons: E2E blocked on publish
- Implement WASM in Traverse as part of this workstream — pros: coordinated; cons: crosses repos / slows Phase 1
- UI fixtures as primary demo path — pros: unblocks UI; cons: not a true embedded ref app

**Recommendation:** Registry publish; fixtures only for unit tests.

**Decision:** App-References stays UI-only and consumes digest-pinned registry artifacts. Phase 1 must track required publish/digest dependencies so Loop is not surprise-blocked. Fixtures are for conformance unit tests only, not the primary demo path.

**Why:** Matches `consume-product-wasm-agents` and architecture boundary.

### Phase 1 app inventory

**Question:** What counts as “all the ref apps” for Phase 1?

**Options considered:**
- Primary product clients only — pros: finite; cons: demos may lag
- Primaries + all demos/kits — pros: nothing in `apps/` outdated; cons: huge surface
- Primaries now; demos upgrade-or-remove in same wave — pros: no zombie apps without pretending samples are products; cons: may retire samples

**Recommendation:** Primaries + hard compat-or-remove for demos.

**Decision:** Update `traverse-starter`, `meeting-notes`, `doc-approval`, `trace-explorer`. Demos/kits (`react-demo`, `browser-consumer`, `android-demo`, `macos-demo`, `youaskm3-starter-kit`, etc.) get an upgrade-or-retire inventory in the same wave.

**Why:** Keeps the ref-app bar on real products while enforcing “no leftovers.”

### Demo retirement plan

**Question:** How should demo retirement work?

**Options considered:**
- Compat gate then delete in-repo via tickets — pros: clean tree; cons: irreversible without git history
- Archive folder/repo cooling-off — pros: softer; cons: junk drawer risk
- CI-fail only, no deletion — pros: pressure without deciding fate; cons: half-products remain

**Recommendation:** Delete via Project 2 tickets with docs/CI scrub.

**Decision:** Phase 1 ends with a written inventory (`upgrade` | `retire` per demo). Retirements are Project 2 tickets that remove the app, drop CI jobs, and update README / design-language / getting-started in the same PR. README gets a short “Retired demos” note.

**Why:** Retirement must be planned and visible, not silent bitrot.

### Phase 1 Definition of Done

**Question:** What proves state machine + capability events work on every ref app?

**Options considered:**
- Automated event-fixture conformance + thin embedded smoke — pros: regression-proof; cons: harness work
- Live smoke matrix only — pros: real stack; cons: flaky / weak ongoing guard
- Audit + doc matrix only — pros: fastest; cons: easy to regress

**Recommendation:** Fixtures + existing embedded smokes.

**Decision:** Shared event-fixture tests assert UI maps runtime/capability events → states such as `loading | loaded | blocked | ended | error` (and capability-state updates). CI runs them per primary app/platform already in CI; keep/extend embedded smokes where toolchains already support them.

**Why:** Durable guardrail after registry churn; matches App-Refs quality gates.

### Ticket slicing

**Question:** How should we slice Project 2 tickets?

**Options considered:**
- Per primary app family — pros: claimable; cons: duplicated fixture contracts
- Foundational harness ticket, then per-app apply — pros: one event→UI contract; cons: apps wait on harness merge
- Per platform across all apps — pros: embedder depth; cons: products half-updated across PRs

**Recommendation:** Harness first, then per-app.

**Decision:**
1. Shared event fixtures + mapping helpers/docs (foundational)
2. Per-app apply tickets: traverse-starter, meeting-notes, doc-approval, trace-explorer
3. Demo upgrade-or-retire inventory + retire/upgrade tickets
4. Loop multi-OS app (WF1), blocked on registry publish digests
5. Follow-up: meeting-notes missing native clients (see platform bar)

**Why:** One shared contract; one ticket = one agent; no four divergent harnesses.

### Platform bar

**Question:** What is the platform bar for full ref-app parity?

**Options considered:**
- Event-contract on existing clients; Loop = all seven OS; meeting-notes natives follow-up — pros: bounded Phase 1; Loop as gold standard; cons: meeting-notes matrix stays incomplete until follow-up
- All products to all seven OS including meeting-notes + Loop — pros: no incomplete products; cons: huge porting before Loop
- Loop matches meeting-notes (web + Linux + CLI) — pros: smaller; cons: another incomplete product ref

**Recommendation:** Loop = all OS; meeting-notes gap filed as follow-up.

**Decision:** Phase 1 updates every *existing* client. Loop ships web, macOS, iOS, Android, Windows, Linux GTK, CLI (same bar as traverse-starter / doc-approval). Explicit follow-up ticket to complete meeting-notes natives. Trace Explorer remains web-only (debugger, not a product shell).

**Why:** Don’t block event-contract work on meeting-notes ports; don’t leave the gap untracked.

### Decision log location

**Question:** Where should this log live?

**Decision:** `docs/decision-log.md`

**Why:** Discoverable shared log for future brainstorms.

---

### Agreed execution plan (summary)

| Phase | Work | Done when |
|---|---|---|
| **1a** | Shared event-fixture harness + docs | One contract for runtime + capability event → UI state mapping; CI-ready helpers |
| **1b** | Apply harness to primary apps | starter, meeting-notes, doc-approval, trace-explorer green on existing platforms |
| **1c** | Demo inventory | Each demo `upgrade` or `retire`; retire tickets scrub code/CI/docs; README “Retired demos” |
| **1d** | Registry dependency tracker | `docs/loop-registry-deps.md` — WF1 capability digests published (2026-08-23); in-app workflow compose OK |
| **2** | `apps/loop/` WF1, all seven OS | Digest-pinned agents; subscribe to state machine + capability events; same CI bar as starter |
| **Follow-up** | meeting-notes remaining natives | iOS / macOS / Android / Windows clients |
| **Later** | Loop WF3 (nudge hero) | After WF1 ref app is green |

### Explicitly deferred

- Loop WF3 (follow-up & nudge) and WF2/WF4/WF5 as first demo
- Implementing capability WASM inside App-References
- Using recorded fixtures as the primary Loop demo path
- Filling meeting-notes native gaps inside Phase 1
- Expanding Trace Explorer beyond web

---

## 2026-08-24 — Next App-Refs slice after Traverse Specs 114/115

**Context:** Project 2 Ready was empty. Traverse ratified Specs 114 (MCP capability search) and 115 (browser-verified entrypoint execution), closed Mode A spec ticket #1125, and opened Ready spec #1132 (verified public contract-metadata cache). App-Refs asked what to do next.

### Next slice

**Question:** Where should the next App-References slice go?

**Options considered:**
- Board hygiene + park MCP consumer work as Blocked — pros: honest board; no fake Ready; tracks Traverse without implementing against unshipped hosts; cons: no new App-Refs code this turn
- Promote Loop WF3 to Ready and implement — pros: independent product work now that WF1 is Done; cons: ignores the Traverse progress that prompted the question
- Wait with no board/docs changes until Traverse #1132 + Mode A implement are Ready — pros: zero extra tickets; cons: Project 2 stays stale (In Progress Mode B scaffold, leftover Future natives)
- File Spec 114/115 consumer tickets as Ready and start docs/smoke now — pros: looks like progress; cons: would fake catalog/browser behavior the runtime does not serve yet

**Recommendation:** Board hygiene + park MCP consumer work as Blocked.

**Decision:** Board hygiene + park MCP consumer work as Blocked.

**Why:** Ready is empty for a real reason; the next honest consumer work is Mode A kit catalog after Traverse lands #1132 and implement children. Keep Loop WF3 Future.

### Ticket shape

**Question:** How should Spec 114/115 consumer work be parked without fake-Ready tickets?

**Options considered:**
- Retarget existing tickets only — pros: no duplicate backlog; catalog + Mode B tickets already exist; cons: Spec 115 browser path is only implied, not a dedicated App-Refs ticket
- One new Blocked umbrella for Spec 114/115 consumers — pros: visible new work; cons: overlaps `llm-mcp-traverse-starter-catalog`
- Two new Blocked tickets (MCP search façade + browser Spec 115) — pros: precise DoD later; cons: over-filing before Traverse implement exists

**Recommendation:** Retarget existing tickets only.

**Decision:** Retarget existing tickets only.

**Why:** `llm-mcp-traverse-starter-catalog` already is the Mode A kit-catalog consumer; Mode B stays on `llm-mcp-embedded-host`. Do not invent Ready work.

### Stale meeting-notes Future ticket

**Question:** Wave 2 already shipped meeting-notes iOS/macOS/Android/Windows. What should happen to `meeting-notes-remaining-natives`?

**Options considered:**
- Mark Done with a note pointing at #236 — pros: Future ticket intent is satisfied; single Done record; cons: two ticket IDs point at the same ship
- Cancel as duplicate of `meeting-notes-wave2-os-ports` — pros: no double-count; cons: Future item disappears without a Done trail
- Keep Future (treat Wave 2 as incomplete) — pros: none; cons: contradicts the tree and README all-OS matrix

**Recommendation:** Mark Done, note #236.

**Decision:** Mark Done, note #236.

**Why:** The leftover Future item’s DoD (add the missing natives) is met by `meeting-notes-wave2-os-ports` (#236).

### Spec 119 Mode A host (2026-08-25)

**Question:** Is Traverse spec `119-verified-registry-mcp-mode-a` approved for App-Refs to treat as the Mode A consumer contract?

**Decision:** Approved. Artifact is on Traverse main (PR #1146); status **Approved (2026-08-25)**.

**Why:** User confirmed approval. App-Refs catalog ticket stays Blocked until the Mode A binary/implement lands; v1 discovery is public registry entries, not hardcoded kit content groups (FR-007).

---

## 2026-08-25 — Registry MCP on reference apps (question 4)

**Context:** User asked whether each OS/target has a demo that uses registry MCP. Answer was no. Follow-up: work on that gap.

### What “use registry MCP” means

**Question:** OS shells embed WASM; MCP is a separate LLM façade; Spec 119 Mode A is approved but not implemented. What should we build?

**Options considered:**
- Keep OS apps embedded-only; prove registry MCP via Claude/Cursor façades — pros: matches constitution Phase 3 and the LLM plan; cons: not a per-OS MCP UI
- Keep embed as the app; add a per-OS MCP companion README/config — pros: visible on every OS folder; cons: duplicates Mode A without a host
- Change OS apps to call `traverse-mcp` — pros: literal reading of “each OS”; cons: replaces embedded production path; constitution violation

**Recommendation:** Keep OS apps embedded-only; prove registry MCP via Claude/Cursor façades.

**Decision:** Keep OS apps embedded-only; prove registry MCP via Claude/Cursor façades.

**Why:** MCP is the LLM façade, not the OS-shell production path.

### App-Refs slice now vs wait

**Question:** Spec 119 is Approved but `traverse-mcp` does not serve Mode A yet. What should App-Refs do now?

**Options considered:**
- Scaffold Spec 119 Mode A consumer now, fail-closed until the host ships — pros: honest consumer contract in-tree; cons: launcher exits non-zero
- Wait until Traverse ships the host — pros: no extra scaffold; cons: App-Refs stays silent on the consumer shape
- Implement Mode A in the Traverse repo — pros: unblocks live kit execute; cons: wrong repo for this thread

**Recommendation:** Scaffold Spec 119 Mode A consumer now, fail-closed.

**Decision:** Scaffold Spec 119 Mode A consumer now, fail-closed (`llm-mcp-mode-a-spec119-scaffold`).

**Why:** Same pattern as Mode B: document the contract, refuse expedition fallback, keep catalog execute Blocked until implement.

---

## 2026-08-25 — Persona E2E bar (kit-runner first)

**Context:** User asked whether each OS/target has a ref app with state machine, capability load, configuration, and workflow; whether docs are current; and how to test end-to-end with multiple personas who want to **create** Traverse apps using App-References.

### First bar vs create-new-app

**Question:** Is the first E2E proof “run the existing kit on each OS” or “author a brand-new app id”?

**Options considered:**
- Kit-runner first (existing `traverse-starter` / siblings on each OS) — pros: apps already exist; finds doc/onboarding bugs immediately; cons: does not prove `traverse-cli app new` → App-Refs layout
- Greenfield author E2E first — pros: matches “create apps” wording; cons: blocked by CLI scaffold vs `manifests/<app>/app.manifest.json` mismatch; delays catching stale docs
- Full N apps × 7 OS matrix in one wave — pros: complete coverage; cons: PR CI cannot prove Apple/Windows/Android; too large for one ticket

**Recommendation:** Kit-runner first.

**Decision:** First bar is **kit-runner**: existing primary shells on each OS (state machine, `registry_ref` caps, workspace config, workflow). New-app author E2E is Future `new-app-author-e2e`.

**Why:** Primaries already ship 7 OS. The honest gap is stale docs + sidecar onboarding, not missing shells. Creating a new app is a second product path.

### How to prove it

**Question:** What is the proof method?

**Options considered:**
- Docs + persona runbook + make `onboarding_check.sh` embedded-first; keep CI as web+CLI PR smoke + native nightly — pros: matches existing CI truth; cons: humans still dogfood natives
- Require all-OS live CI on every PR — pros: strongest gate; cons: not how this repo’s runners work
- Only automated web+CLI — pros: cheapest; cons: does not answer “multiple OS personas”

**Recommendation:** Docs + runbook + embedded onboarding; keep existing CI split.

**Decision:** Proof = stale-doc scrub + [`kit-runner-persona.md`](kit-runner-persona.md) + rewrite `onboarding_check.sh` so it does not treat `traverse-cli serve` / `:8787` as the production path. PR gate stays `embedded_smoke` (web+CLI); natives stay nightly + human runbook.

**Why:** CI already encodes the split. Pretending every merge proves seven OS would be a false bar.

### Ticket scope

**Question:** What lands in `kit-runner-persona-docs` vs later?

**Decision:** This ticket is docs + onboarding rewrite + repository_checks for the runbook. App code changes only if a persona step is broken in a way docs cannot fix. File Project 2 drafts for real bugs found during dogfood. `new-app-author-e2e` stays Future until kit-runner lands.

**Why:** Smallest change that makes the persona test runnable and the docs honest.

---

## 2026-08-26 — New-app author E2E

**Context:** Personas want to **create** Traverse apps with App-Refs. Kit-runner (#273) covers running existing shells. `traverse-cli app new` still emits `apps/<id>/manifest.json` (empty); embedders load `manifests/<id>/app.manifest.json`.

**Question:** Change Traverse CLI in this ticket, check in a throwaway product app, or remap + prove Web?

**Options considered:**
- Implement `app new` filename change in Traverse — pros: one layout; cons: wrong repo for this thread
- Check in `apps/persona-demo` as a fifth primary — pros: visible app; cons: duplicate starter WASM; CI/workspace cost
- Remap helper + fixture CI + Web host rewrite; seed from traverse-starter; no new product app in tree — pros: honest layout proof; cons: live `app new` still needs TRAVERSE_REPO locally

**Recommendation:** Remap helper + Web proof in CI.

**Decision:** Ship `docs/new-app-author.md`, `scripts/ci/remap_app_new_to_kit.sh`, and `scripts/ci/new_app_author_check.sh`. First slice reuses `traverse-starter.pipeline` / `registry_ref`. Won’t Fix: renaming Traverse `app new` output in this repo.

**Why:** Constitution: no invented business fields. Empty `app new` is not a product app. Web is the one OS in this slice; more OS uses add-platform-client after Web works.

---

## 2026-09-05 — Two-app reuse contract (Traverse #1168)

**Context:** Traverse #1168 needs evidence that a published capability is a reusable platform unit. App-References already has two independent apps that name `meeting-notes.process`, but they can resolve different artifacts.

**Question:** Which published capability and which two apps should the immutable-release proof use?

**Options considered:**
- `meeting-notes.process` consumed by `meeting-notes` + `loop` — pros: distinct product workflows; Loop already pins 1.3.2; I/O schema compatible; cons: meeting-notes still on the 1.0.0 digest until `#282`
- `traverse-starter.process` + a second kit shell — pros: familiar kit; cons: no second independent product purpose
- `core.extract-action-items` + meeting-notes — pros: published core cap; cons: meeting-notes has no extract step

**Recommendation:** `meeting-notes.process` 1.3.2 for meeting-notes + Loop.

**Decision:** Exact pin `1.3.2` / digest `sha256:ec192a0c…` for both apps. Record in [`two-app-reuse-contract.md`](two-app-reuse-contract.md) and ADR [`0006`](adr/0006-two-app-reuse-contract.md). No manifest alignment in this ticket.

**Why:** Same capability already sits on two `app_id` boundaries with different user-facing purposes. Floating `^` ranges are exactly what #1168 forbids.

---

## 2026-09-05 — Blocked tickets ownership walk

**Context:** Brainstorm over Project 2 Blocked tickets to classify ownership (on user vs Traverse vs defer) and decide board hygiene vs upstream push order. Live board query was intermittently rate-limited; inventory from `AGENTS.md` + open Traverse issues #1240/#1241/#1242.

### Brainstorm goal

**Question:** What should this brainstorm decide?

**Options considered:**
- Prioritize which Traverse blocker to push next — pros: focuses unlock; cons: skips hygiene
- Decide App-Refs interim workarounds while Traverse is blocked — pros: keeps shipping; cons: fake-runtime risk
- Board hygiene only (keep / Future / narrow DoD) — pros: cleans false urgency; cons: no upstream move
- Walk every blocked ticket and classify ownership — pros: full map; collapses shared root causes; cons: longer

**Recommendation:** Ownership walk first.

**Decision:** Walk every blocked ticket and classify (on you / on Traverse / defer).

**Why:** Three of five share two Traverse issues; a pass usually collapses the set before picking priority or workarounds.

### LLM MCP cluster

**Question:** How to classify `llm-mcp-traverse-starter-catalog`, `llm-mcp-embedded-host`, and `llm-mcp-0-10-live-cutover`?

**Options considered:**
- On Traverse only; leave all Blocked — pros: honest; cons: no prioritization signal
- On user to prioritize/assign Traverse #1241/#1242 — pros: names unlock; cons: needs Traverse ownership
- Defer whole cluster to Future — pros: less Blocked noise; cons: hides Approved Spec 119 wait
- Split: Mode A (#1241) active Blocked; Mode B (#1242) → Future — pros: Mode A unblocks kit path first; cons: cutover umbrella spans both

**Recommendation:** Split Mode A / Mode B.

**Decision:** Mode A stays active Blocked on Traverse [#1241](https://github.com/traverse-framework/Traverse/issues/1241); Mode B (`llm-mcp-embedded-host`) → Future on [#1242](https://github.com/traverse-framework/Traverse/issues/1242).

**Why:** Mode A is the Cursor/Claude kit path; Mode B is a separate host product.

### Cutover umbrella

**Question:** What happens to `llm-mcp-0-10-live-cutover` after the Mode A/B split?

**Options considered:**
- Narrow DoD to Mode A only; stay Blocked — pros: simple; cons: Mode B cutover needs a home
- Split into Mode A + Mode B cutover tickets — pros: clean; cons: overlaps live tickets
- Keep umbrella Blocked on both — pros: no rewrite; cons: Mode B blocks Mode A Done
- Cancel/absorb into `llm-mcp-traverse-starter-catalog` + `llm-mcp-embedded-host` — pros: fewest tickets; cons: lose explicit post-pin checklist unless folded into those DoDs

**Recommendation:** Absorb/cancel umbrella.

**Decision:** Cancel/absorb `llm-mcp-0-10-live-cutover` into the Mode A catalog and Mode B embedded-host tickets (pin already Done via `pin-ci-traverse-0-10`).

**Why:** After the pin, the umbrella duplicates the two live tickets.

### Two-app host execute

**Question:** How to classify `two-app-reuse-host-execute` (Traverse [#1240](https://github.com/traverse-framework/Traverse/issues/1240))?

**Options considered:**
- On Traverse only; leave Blocked — pros: no fake host path; cons: public BundleEmbedder proof incomplete
- On user to prioritize #1240 — pros: names unlock; cons: needs Traverse triage ownership
- Downgrade to Future with materialize-retire wave — pros: less noise; cons: understates open bug
- Accept wasmtime-only as Done; Future/Cancel host-execute — pros: paper-unblocks reuse; cons: weakens public-host proof

**Recommendation:** Stay honestly Blocked on #1240.

**Decision:** Leave `two-app-reuse-host-execute` Blocked on Traverse #1240; do not redefine Done around wasmtime alone.

**Why:** Ticket exists for public BundleEmbedder proof; App-Refs must not invent substitute WASM.

### Lifecycle predecessor

**Question:** What to do with `two-app-reuse-lifecycle` (board note still “After `#282`”)?

**Options considered:**
- Move toward Ready (execute Done is enough) — pros: clears false Blocked; cons: may need registry behaviors
- Retarget Blocked to host-execute / #1240 — pros: if DoD needs BundleEmbedder; cons: couples unrelated concerns
- Future until a real published upgrade/deprecation — pros: live release train; cons: long wait
- Blocked on user for Spec/DoD rewrite first — pros: avoids wrong proof; cons: design beat before Ready

**Recommendation:** Ready path if DoD is pin/upgrade semantics without BundleEmbedder.

**Decision:** Not blocked on `#282` (execute already Done as #286) or on #1240; proceed to Ready after DoD is made checkable.

**Why:** Written scope is upgrade/deprecation outcomes for the shared pin pair; no BundleEmbedder requirement in the contract table.

### Lifecycle Spec/DoD shape

**Question:** Before Ready, how to make lifecycle DoD claimable?

**Options considered:**
- Ready as-is; flesh DoD in implementing PR — pros: fastest; cons: weak claim gate
- Full Spec/DoD rewrite brainstorm first — pros: strongest gate; cons: extra design pass
- Future until registry publishes next `meeting-notes.process` — pros: real train; cons: App-Refs can’t drive calendar
- Fixture-only pin flip + documented deprecation handling (no new registry release) — pros: claimable soon; honest; cons: weaker than production upgrade proof

**Recommendation:** Fixture-level DoD, then Ready.

**Decision:** Define DoD around fixture-only pin flip + documented deprecation handling (explicit non-claim of production release-train proof), then set status Ready.

**Why:** Keeps the ticket honest and claimable without waiting on a registry publish or BundleEmbedder.

### Next action order

**Question:** With two honest Blocked tickets left, what to push first?

**Options considered:**
- Prioritize Traverse #1241 (Mode A kit MCP) — pros: live kit façades; cons: host-execute stays stuck
- Prioritize Traverse #1240 (BundleEmbedder) — pros: completes #1168 host proof; cons: MCP stays expedition-only
- App-Refs board hygiene first; Traverse priority later — pros: lifecycle becomes claimable now; cons: upstream idle briefly
- Parallel triage of #1241 + #1240 plus hygiene — pros: no false sequencing; cons: split attention

**Recommendation:** Hygiene first, then #1241.

**Decision:** Apply App-Refs board hygiene first (Mode B → Future; cancel cutover umbrella; Ready lifecycle with fixture DoD; refresh `AGENTS.md` / README blockers). Then push Traverse [#1241](https://github.com/traverse-framework/Traverse/issues/1241) as the higher-leverage remaining Blocked unlock. Leave #1240 Blocked without redefining it.

**Why:** Hygiene unlocks Ready work without waiting on Traverse; Mode A MCP is the stronger demo unlock of the two remaining upstream bugs.

### What was explicitly deferred

- Assigning/staffing Traverse #1240 vs #1241 beyond “#1241 after hygiene”
- Any App-Refs interim workaround that fakes kit MCP or BundleEmbedder success
- Production registry release-train proof for lifecycle (fixture-only by design)
