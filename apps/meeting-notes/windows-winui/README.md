# meeting-notes (Windows WinUI 3)

**Runtime mode: Embedded** - in-process `TraverseEmbedder` (.NET) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` sidecar is required.

Native Windows client for the `meeting-notes` reference app.

## Prerequisites

- Windows 10 1809+ (build 17763) or Windows 11
- Visual Studio 2022 with the Windows App SDK and .NET desktop development workloads
- Bundled runtime assets under `MeetingNotes/Assets/bundles/meeting-notes/` (synced below)

## Sync the embedded bundle

```powershell
$env:TRAVERSE_REPO = "C:\temp\traverse"   # clone of traverse-framework/Traverse
bash scripts/ci/sync_winui_meeting_notes_bundle.sh
```

This copies `runtime/runtime.wasm` + `runtime-release.json` (digest pin) and app manifests into the WinUI Assets tree.

## Settings

Open Settings (gear icon) to set:

- Workspace - default `local-default`
- Bundle path (optional) - override the bundled Assets root

No Runtime URL is required in embedded mode.

## Build and run

From Visual Studio 2022, open `MeetingNotes.sln` and run on x64.

Or from a Developer PowerShell:

```powershell
cd apps\meeting-notes\windows-winui
dotnet build MeetingNotes.sln -c Release
dotnet test MeetingNotes.sln -c Release
dotnet run --project MeetingNotes\MeetingNotes.csproj
```

## Architecture

| File | Role |
|---|---|
| `EmbeddedHost.cs` | `RuntimeTraverseEmbedder` / `InMemoryTraverseEmbedder` boundary |
| `ExecutionViewModel.cs` | MVVM submit + Embedded Ready/Unavailable status |
| `HomePage.xaml` | Transcript input, output fields, trace |
| `SettingsPage.xaml` | Workspace + optional bundle path |
| `MainWindow.xaml` | Navigation shell - Embedded + status + workspace + workflow |

Vendored SDK: [`vendor/traverse-embedder-dotnet/`](../../../../vendor/traverse-embedder-dotnet/) (Traverse Spec 068 / 071).

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md). Zone 1 shows **Embedded** with Ready / Unavailable / Starting.
