# Reference Apps

[![CI](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml)

UI examples for [Traverse](https://github.com/traverse-framework/Traverse).  
**Same business logic (WASM agents in Traverse) → many UI shells here** (Web, macOS, iOS, Android, Windows, Linux, CLI).

**Start here:** [traverse-starter on Web](apps/traverse-starter/web-react/) (commands below).  
**You need:** Node.js 24+ (see `.nvmrc`) and a local [Traverse](https://github.com/traverse-framework/Traverse) clone — set `TRAVERSE_REPO` and run the sync script for your platform before the app can load WASM.  
**Success looks like:** submit a note and see title, tags, note type, next action, and status filled in by the runtime (the UI does not invent those fields).

> **Agents / LLMs:** this repo is UI-only — render runtime fields, never compute business output. Claim work via [`AGENTS.md`](AGENTS.md). Authoring the capability a UI here consumes? See [traverse-framework/claude-skills](https://github.com/traverse-framework/claude-skills) for a Claude Skill covering contract authoring, composition, and validation.

---

## Apps we have built

| App | What it does | Start here |
|---|---|---|
| **traverse-starter** | Submit a short note → title, tags, note type, next action, status | [web](apps/traverse-starter/web-react/) · [all OS](#by-os--target) |
| **doc-approval** | Paste a document → type, parties, amounts, confidence, recommendation | [web](apps/doc-approval/web-react/) |
| **meeting-notes** | Paste a transcript → action items, decisions, follow-ups, summary | [web](apps/meeting-notes/web-react/) |
| **trace-explorer** | Browse execution traces (debugger — not a product shell to copy) | [web](apps/trace-explorer/web-react/) |

**Extra demos / kits** — useful samples, **not** the production pattern to copy (prefer traverse-starter / doc-approval / meeting-notes):

| Demo | Path |
|---|---|
| React browser demo | [`apps/react-demo/`](apps/react-demo/) |
| Android demo | [`apps/android-demo/`](apps/android-demo/) |
| macOS demo | [`apps/macos-demo/`](apps/macos-demo/) |
| Browser consumer façade | [`apps/browser-consumer/`](apps/browser-consumer/) |
| youaskm3 starter kit | [`apps/youaskm3-starter-kit/`](apps/youaskm3-starter-kit/) |

---

## By OS / target

Open the folder, then the tool named below. Full steps (sync + run) are in that folder’s `README.md`.

| Target | Open this | Then |
|---|---|---|
| **Web** | [`apps/traverse-starter/web-react/`](apps/traverse-starter/web-react/) | `npm run dev` from repo root (after web sync) |
| **macOS** | [`apps/traverse-starter/macos-swift/`](apps/traverse-starter/macos-swift/) | Open `TraverseStarterMac.xcodeproj` in Xcode → Run |
| **iOS** | [`apps/traverse-starter/ios-swift/`](apps/traverse-starter/ios-swift/) | Mac + Xcode: open `TraverseStarter.xcodeproj` → Run (Simulator) |
| **Android** | [`apps/traverse-starter/android-compose/`](apps/traverse-starter/android-compose/) | Open the folder in Android Studio → Run |
| **Windows** | [`apps/traverse-starter/windows-winui/`](apps/traverse-starter/windows-winui/) | Open `TraverseStarter.sln` in Visual Studio (WinAppSDK). Sync script needs Git Bash/WSL |
| **Linux (GTK)** | [`apps/traverse-starter/linux-gtk/`](apps/traverse-starter/linux-gtk/) | Rust + GTK4 deps, then `cargo run` (see folder README) |
| **CLI** | [`apps/traverse-starter/cli-rust/`](apps/traverse-starter/cli-rust/) | Rust, then `cargo run` / `cargo install` (see folder README) |

Same apps on other platforms (`—` = not shipped yet):

| App | Web | macOS | iOS | Android | Windows | Linux | CLI |
|---|---|---|---|---|---|---|---|
| traverse-starter | [link](apps/traverse-starter/web-react/) | [link](apps/traverse-starter/macos-swift/) | [link](apps/traverse-starter/ios-swift/) | [link](apps/traverse-starter/android-compose/) | [link](apps/traverse-starter/windows-winui/) | [link](apps/traverse-starter/linux-gtk/) | [link](apps/traverse-starter/cli-rust/) |
| doc-approval | [link](apps/doc-approval/web-react/) | [link](apps/doc-approval/macos-swift/) | [link](apps/doc-approval/ios-swift/) | [link](apps/doc-approval/android-compose/) | [link](apps/doc-approval/windows-winui/) | [link](apps/doc-approval/linux-gtk/) | [link](apps/doc-approval/cli-rust/) |
| meeting-notes | [link](apps/meeting-notes/web-react/) | — | — | — | — | [link](apps/meeting-notes/linux-gtk/) | [link](apps/meeting-notes/cli-rust/) |

---

## Same business logic on multiple OS

1. **Logic lives in Traverse** (WASM agents + workflows) — not in these UI folders.
2. **Each OS folder** under `apps/<app>/` is only a shell: sync the bundle, submit input, show runtime fields.
3. **Reuse the pattern:** get one shell working ([getting started](docs/getting-started-embedded.md)), then add another OS ([add-platform recipe](docs/add-platform-client.md)). Sync scripts per OS: [`docs/runtime-bundle-sync.md`](docs/runtime-bundle-sync.md).

**Fastest try (Web):**

```bash
git clone https://github.com/traverse-framework/Traverse.git ../Traverse
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps
npm install
export TRAVERSE_REPO="$(cd ../Traverse && pwd)"
bash scripts/ci/sync_web_starter_bundle.sh   # required — copies runtime.wasm + manifests
npm run dev                                  # http://localhost:5173
```

Without `TRAVERSE_REPO` + sync, the embedded host has no bundle and the app will not run workflows.

Other web apps (same install; sync that app’s bundle first — see its README):

```bash
npm run dev -w apps/doc-approval/web-react
npm run dev -w apps/meeting-notes/web-react
```

---

## More docs (when you need them)

| Doc | Use when |
|---|---|
| [`docs/getting-started-embedded.md`](docs/getting-started-embedded.md) | First full walkthrough |
| [`docs/add-platform-client.md`](docs/add-platform-client.md) | Add another OS shell |
| [`docs/production-playbook.md`](docs/production-playbook.md) | Ship / packaging guide |
| [`docs/runtime-bundle-sync.md`](docs/runtime-bundle-sync.md) | Which sync script for which OS |
| [`AGENTS.md`](AGENTS.md) | Claiming Project 2 tickets |
