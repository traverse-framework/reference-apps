# traverse-starter (Windows WinUI 3)

**Runtime mode: Embedded** — in-process `TraverseEmbedder` (.NET) loads digest-pinned `runtime/runtime.wasm`. No `traverse-cli serve` required.

Native Windows client for the `traverse-starter` reference app.

## Prerequisites

- **Windows 10 1809+** (build 17763) or Windows 11
- **Visual Studio 2022** with the **Windows App SDK** and **.NET desktop development** workloads
- Bundled runtime assets under `TraverseStarter/Assets/bundles/traverse-starter/` (synced below)

## Sync the embedded bundle

```powershell
$env:TRAVERSE_REPO = "C:\temp\traverse"   # clone of traverse-framework/Traverse
bash scripts/ci/sync_winui_starter_bundle.sh
```

This copies `runtime/runtime.wasm` + `runtime-release.json` (digest pin) and app manifests into the WinUI Assets tree.

## Settings

Open **Settings** (gear icon) to set:

- **Workspace** — default `local-default`
- **Bundle path** (optional) — override the bundled Assets root

No Runtime URL is required in embedded mode.

## Build and run

From Visual Studio 2022, open `TraverseStarter.sln` and run on x64.

Or from a Developer PowerShell:

```powershell
cd apps\traverse-starter\windows-winui
dotnet build TraverseStarter.sln -c Release
dotnet test TraverseStarter.sln -c Release
dotnet run --project TraverseStarter\TraverseStarter.csproj
```

## Architecture

| File | Role |
|---|---|
| `EmbeddedHost.cs` | `RuntimeTraverseEmbedder` / `InMemoryTraverseEmbedder` boundary |
| `ExecutionViewModel.cs` | MVVM submit + Zone 1 Ready/Unavailable |
| `HomePage.xaml` | Note input, runtime-owned output fields, trace |
| `SettingsPage.xaml` | Workspace + optional bundle path |
| `MainWindow.xaml` | Navigation shell — Embedded + status + workspace + workflow |

Vendored SDK: [`vendor/traverse-embedder-dotnet/`](../../../../vendor/traverse-embedder-dotnet/) (Traverse Spec 068 / 071).

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md). Zone 1 shows **Embedded** with Ready / Unavailable / Starting.
