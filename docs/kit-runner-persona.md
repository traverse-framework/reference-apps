# Kit-runner persona bar

**Audience:** someone using App-References as the copy-paste kit — run the **existing** `traverse-starter` (and siblings) on an OS they care about.

This is the first end-to-end bar. It is **not** “create a brand-new app from scratch” (Project 2 **Ready:** `new-app-author-e2e`) and **not** registry MCP on OS shells (LLM façades only; Mode A host still unimplemented).

Related: [`getting-started-embedded.md`](getting-started-embedded.md) · [`production-playbook.md`](production-playbook.md) · [`add-platform-client.md`](add-platform-client.md) · root [`README.md`](../README.md)

## What must be true (kit bar)

For **each** primary OS target, a persona can:

| Capability | Where it lives | How you know it worked |
|---|---|---|
| **State machine** | `app.manifest.json` `state_machine` + Spec 001/002 event subscribe | UI/CLI shows `idle → loading → loaded` (or `error` / `blocked`) from embedder events, not a local timer |
| **Load capabilities** | Component `registry_ref` + digest-pinned bundle sync | Workflow runs; output fields come from runtime WASM (title/tags/… or domain equivalents) |
| **Configuration** | `config_schema` / `default_config` / `workspace_defaults`; OS settings where present | Health/settings show `workspace_id` (default `local-default`) |
| **Workflow** | `workflows[]` (starter: `traverse-starter.pipeline`) | One submit runs the chained capabilities; UI does not call each cap itself |

Primary apps on all seven OS: `traverse-starter`, `doc-approval`, `meeting-notes`, `loop`. Trace Explorer is web-only (debugger). LLM MCP is a **separate** façade.

## CI vs human

| Proof | Platforms | When |
|---|---|---|
| `bash scripts/ci/embedded_smoke.sh` (`EMBEDDED_SMOKE_EXPECT=linux`) | Web + CLI required | Every PR |
| Nightly native jobs | macOS, iOS build, Android, Windows, GTK | Nightly |
| This runbook | All seven | Human / agent dogfood |

Do not treat PR CI as “all OS proven on every merge.”

## Personas (traverse-starter)

Set `TRAVERSE_REPO` to a Traverse checkout. Do **not** start `traverse-cli serve`.

Pass criteria (all personas):

1. Host reports **Embedded** / ready (not a required loopback URL).
2. Submit a fixed note, e.g. `Meeting with Alice about project X`.
3. Runtime-owned fields appear: **title**, **tags**, **note type**, **suggested next action**, **status**.
4. Loading/error/ready follow embedder events (Spec 001).
5. Workspace is `local-default` unless you changed settings.

| Persona | Sync | Run | Extra |
|---|---|---|---|
| **Web** | `bash scripts/ci/sync_web_starter_bundle.sh` | `npm run dev` → http://localhost:5173 | [`apps/traverse-starter/web-react/README.md`](../apps/traverse-starter/web-react/README.md) |
| **CLI** | `bash scripts/ci/phase2_link_traverse.sh` | `cargo run -p traverse-starter-cli -- health --json` then `-- run --note "…"` | From `apps/traverse-starter/` |
| **Linux GTK** | same link | `cargo run -p traverse-starter-gtk` | GTK4 / Adwaita deps |
| **Android** | `bash scripts/ci/sync_android_starter_bundle.sh` | Android Studio Run | [`android-compose/README.md`](../apps/traverse-starter/android-compose/README.md) |
| **iOS** | `bash scripts/ci/sync_swift_starter_bundle.sh` | Xcode Simulator | [`ios-swift/README.md`](../apps/traverse-starter/ios-swift/README.md) |
| **macOS** | same Swift sync | Xcode Run | [`macos-swift/README.md`](../apps/traverse-starter/macos-swift/README.md) |
| **Windows** | `bash scripts/ci/sync_winui_starter_bundle.sh` | Visual Studio | [`windows-winui/README.md`](../apps/traverse-starter/windows-winui/README.md) |

Same four checks on `doc-approval` / `meeting-notes` / `loop` using that app’s sync script and domain input (document / transcript / WF1 ingest). Platform READMEs name the sync command.

## Local machine check

```bash
bash scripts/ci/onboarding_check.sh
```

Local npm gates always. Manifest / `registry_ref` / runbook probes always. `TRAVERSE_REPO` is optional (check 9 skip). The script does **not** probe `127.0.0.1:8787`.

## Known gaps (do not pretend these are Done)

| Gap | Ticket / note |
|---|---|
| Sync still **materializes** `registry_ref` → local wasm for many hosts | `retire-registry-ref-materialize-hosts` (Future) |
| Registry MCP is not an OS-shell path | `llm-mcp-mode-a-spec119-scaffold` Done (fail-closed); live kit execute `llm-mcp-traverse-starter-catalog` Blocked |
| Creating a **new** app id from CLI + this kit | Ready `new-app-author-e2e` |
| `onboarding_check.sh` is not a merge-blocking CI gate | By design (slow `npm install`); `embedded_smoke` is the PR gate |

## File bugs

If a persona step fails, open a **Project 2** draft (Spec + DoD) — not a GitHub Issue. Include OS, app, command, and whether output fields were invented in the UI.
