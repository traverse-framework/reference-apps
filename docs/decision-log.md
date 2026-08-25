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
