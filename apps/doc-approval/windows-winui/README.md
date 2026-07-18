# doc-approval (Windows WinUI 3)

**Runtime mode: HTTP sidecar (interim)** — Phase 1 HTTP polling against the public Traverse HTTP/JSON API (spec 033). Embedded WASM cutover is tracked in [#116](https://github.com/traverse-framework/reference-apps/issues/116). Requires `traverse-cli serve`. (Web React for this app is already embedded; do not copy its path here.)

Native Windows submitter client for the `doc-approval` reference app.

## Prerequisites

- **Windows 10 1809+** (build 17763) or Windows 11
- **Visual Studio 2022** with the **Windows App SDK** and **.NET desktop development** workloads
- **Traverse HTTP sidecar** running locally

```bash
git clone https://github.com/traverse-framework/Traverse.git C:\temp\traverse
cd C:\temp\traverse && git checkout v0.6.0
cargo run -p traverse-cli -- serve
```

## Runtime URL configuration

Open **Settings** (gear icon in the navigation pane) and set:

- **Runtime URL** — default `http://127.0.0.1:8787`
- **Workspace** — default `local-default`

Values persist in `ApplicationData.Current.LocalSettings`.

## Build and run

From Visual Studio 2022, open `DocApproval.sln` and run on x64.

Or from a Developer PowerShell:

```powershell
cd apps\doc-approval\windows-winui
dotnet build DocApproval.sln -c Release
dotnet test DocApproval.sln -c Release
dotnet run --project DocApproval\DocApproval.csproj
```

## Architecture

| File | Role |
|---|---|
| `TraverseClient.cs` | `HttpClient` wrapper for execute / poll / trace / healthz |
| `ExecutionViewModel.cs` | MVVM polling state machine (`CommunityToolkit.Mvvm`) |
| `HomePage.xaml` | Main view — document input, analysis fields, trace expander |
| `SettingsPage.xaml` | Runtime URL + workspace (`ApplicationData`) |
| `MainWindow.xaml` | Navigation shell with title-bar health strip |

The UI renders runtime-provided pipeline fields only (`analysis.*`, `recommendation.*`).

## Phase 2 (not implemented)

SSE subscription when Traverse ships [#525](https://github.com/traverse-framework/Traverse/issues/525)–[#527](https://github.com/traverse-framework/Traverse/issues/527).

## Design language

Follow [docs/design-language.md](../../../docs/design-language.md).
