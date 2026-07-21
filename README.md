# Reference Apps

[![CI](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/traverse-framework/reference-apps/actions/workflows/ci.yml)

UI examples for [Traverse](https://github.com/traverse-framework/Traverse).  
**Same business logic (WASM) → many UI shells** (Web, macOS, iOS, Android, Windows, Linux, CLI).

---

## Apps we have built

| App | What it does | Start here |
|---|---|---|
| **traverse-starter** | Submit a short note → get title, tags, note type, next action, status | [web](apps/traverse-starter/web-react/) · [all platforms](#by-os--target) |
| **doc-approval** | Paste a document → get type, parties, amounts, confidence, recommendation | [web](apps/doc-approval/web-react/) |
| **meeting-notes** | Paste a transcript → get action items, decisions, follow-ups, summary | [web](apps/meeting-notes/web-react/) |
| **trace-explorer** | Browse execution traces (debugger tool) | [web](apps/trace-explorer/web-react/) |

**Extra demos / kits** (lighter examples, not the main product shells):

| Demo | Path |
|---|---|
| React browser demo | [`apps/react-demo/`](apps/react-demo/) |
| Android demo | [`apps/android-demo/`](apps/android-demo/) |
| macOS demo | [`apps/macos-demo/`](apps/macos-demo/) |
| Browser consumer façade | [`apps/browser-consumer/`](apps/browser-consumer/) |
| youaskm3 starter kit | [`apps/youaskm3-starter-kit/`](apps/youaskm3-starter-kit/) |

---

## By OS / target

Pick your platform. Each link is the example to open first (`traverse-starter` unless noted).  
Full run steps live in that folder’s `README.md`.

| Target | Example to open |
|---|---|
| **Web** | [`apps/traverse-starter/web-react/`](apps/traverse-starter/web-react/) |
| **macOS** | [`apps/traverse-starter/macos-swift/`](apps/traverse-starter/macos-swift/) |
| **iOS** | [`apps/traverse-starter/ios-swift/`](apps/traverse-starter/ios-swift/) |
| **Android** | [`apps/traverse-starter/android-compose/`](apps/traverse-starter/android-compose/) |
| **Windows** | [`apps/traverse-starter/windows-winui/`](apps/traverse-starter/windows-winui/) |
| **Linux (GTK)** | [`apps/traverse-starter/linux-gtk/`](apps/traverse-starter/linux-gtk/) |
| **CLI** | [`apps/traverse-starter/cli-rust/`](apps/traverse-starter/cli-rust/) |

Same pattern for the other apps:

| App | Web | macOS | iOS | Android | Windows | Linux | CLI |
|---|---|---|---|---|---|---|---|
| traverse-starter | [link](apps/traverse-starter/web-react/) | [link](apps/traverse-starter/macos-swift/) | [link](apps/traverse-starter/ios-swift/) | [link](apps/traverse-starter/android-compose/) | [link](apps/traverse-starter/windows-winui/) | [link](apps/traverse-starter/linux-gtk/) | [link](apps/traverse-starter/cli-rust/) |
| doc-approval | [link](apps/doc-approval/web-react/) | [link](apps/doc-approval/macos-swift/) | [link](apps/doc-approval/ios-swift/) | [link](apps/doc-approval/android-compose/) | [link](apps/doc-approval/windows-winui/) | [link](apps/doc-approval/linux-gtk/) | [link](apps/doc-approval/cli-rust/) |
| meeting-notes | [link](apps/meeting-notes/web-react/) | — | — | — | — | [link](apps/meeting-notes/linux-gtk/) | [link](apps/meeting-notes/cli-rust/) |

---

## Same business logic on multiple OS

1. Business logic lives once in Traverse WASM agents (not in these UIs).
2. Each OS folder under `apps/<app>/` is only a shell: submit input, show runtime fields.
3. Copy the pattern: open [`docs/getting-started-embedded.md`](docs/getting-started-embedded.md), then add another OS with [`docs/add-platform-client.md`](docs/add-platform-client.md).

**Fastest try (Web):**

```bash
git clone https://github.com/traverse-framework/reference-apps.git
cd reference-apps
npm install
export TRAVERSE_REPO=/path/to/Traverse   # local Traverse checkout with example WASM
bash scripts/ci/sync_web_starter_bundle.sh
npm run dev                              # http://localhost:5173 — traverse-starter
```

Other web apps:

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
| [`docs/runtime-bundle-sync.md`](docs/runtime-bundle-sync.md) | Sync digest-pinned `runtime.wasm` |
| [`AGENTS.md`](AGENTS.md) | Claiming Project 2 tickets (agents) |
