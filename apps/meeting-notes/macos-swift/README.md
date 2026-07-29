# meeting-notes (macOS SwiftUI)

**Runtime mode: Embedded** — in-process `TraverseEmbedder` (Swift) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` required.

## Sync bundle

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/sync_swift_meeting_notes_bundle.sh
```

Destination: `MeetingNotesMac/Resources/bundles/meeting-notes/`

## Build / run

Open `MeetingNotesMac.xcodeproj` in Xcode → Run.

Shared host + tests: [`../MeetingNotesCore/`](../MeetingNotesCore/)

```bash
cd apps/meeting-notes/MeetingNotesCore && swift test
```
