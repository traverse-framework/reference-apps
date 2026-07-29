# MeetingNotesCore

Shared Swift package for meeting-notes iOS and macOS shells.

- `EmbeddedHost` — `RuntimeTraverseEmbedder` / `InMemoryTraverseEmbedder` boundary
- `AppStateViewModel` — Zone 1 Ready/Unavailable + submit/reset
- `MeetingNotesOutput` — runtime-owned field decoding only

```bash
cd apps/meeting-notes/MeetingNotesCore && swift test
```
