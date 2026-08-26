# New-app author persona

**Audience:** someone who wants to **create a new Traverse app id** using this repo as the kit — not only run `traverse-starter`.

Kit-runner (existing shells on each OS): [`kit-runner-persona.md`](kit-runner-persona.md). Schema: [`app-manifest-schema.md`](app-manifest-schema.md). Extra OS: [`add-platform-client.md`](add-platform-client.md).

## What this ticket proves

A persona can:

1. Run public `traverse-cli app new <id>` (empty, schema-valid scaffold).
2. Remap that tree into App-Refs `manifests/<id>/app.manifest.json`.
3. Seed the **kit bar** from `traverse-starter` (state machine, `registry_ref` caps, config, workflow).
4. Copy the **Web** shell, rewrite app identity + bundle path, keep the public embedder.

First slice **reuses** `traverse-starter.pipeline` and published starter WASM. That is intentional: App-Refs must not invent title/tags/status. A new domain app needs new WASM in Traverse first.

Do **not** start `traverse-cli serve`. Production path is embedded.

## Won’t Fix here (Traverse CLI)

| CLI `app new` | App-Refs / embedders |
|---|---|
| `apps/<id>/manifest.json` | `manifests/<id>/app.manifest.json` |
| Empty `components` / `workflows` | Real `registry_ref` + workflow JSON |
| No `state_machine` | Required for primary shells |
| `workspace_id: <id>-local` | Primaries use `local-default` until you change config |

App-Refs will **not** rename Traverse’s scaffold. Remap with `scripts/ci/remap_app_new_to_kit.sh`. Upstream: ask Traverse to emit `app.manifest.json` from `app new` (examples already use that name). Until then, treat CLI output as a stub, not a product app.

## Recipe (Web)

Work in a scratch directory for `app new` so you do not drop a stub under this repo’s `apps/` product shells.

```bash
export TRAVERSE_REPO=/path/to/Traverse
export APP_REFS=/path/to/reference-apps   # this clone
APP_ID=my-notes                           # your new app id

# 1. Empty governed scaffold (not runnable)
cd /tmp
cargo run -p traverse-cli-rs --manifest-path "$TRAVERSE_REPO/Cargo.toml" -- \
  app new "$APP_ID"

# 2. Remap + seed kit bar (state_machine, registry_ref, config, workflow)
bash "$APP_REFS/scripts/ci/remap_app_new_to_kit.sh" \
  --from "/tmp/apps/$APP_ID" \
  --out "$APP_REFS/manifests/$APP_ID" \
  --app-id "$APP_ID" \
  --seed-from traverse-starter

# 3. Copy Web twin (structure only — do not add business-field math)
mkdir -p "$APP_REFS/apps/$APP_ID"
cp -R "$APP_REFS/apps/traverse-starter/web-react" "$APP_REFS/apps/$APP_ID/web-react"
```

In `apps/<id>/web-react/src/host/embeddedHost.ts` change **only**:

- `DEFAULT_APP_ID` → `'<id>'`
- `DEFAULT_MANIFEST_PATH` → `'/bundles/<id>/app.manifest.json'`

Leave `DEFAULT_WORKFLOW_ID = 'traverse-starter.pipeline'` until Traverse ships a new workflow. Copy the starter Web README **Runtime mode: Embedded** line. Add a `scripts/ci/sync_web_<id>_bundle.sh` wrapper that calls `sync_bundle_core.sh` the same way as `sync_web_starter_bundle.sh` (destination `apps/<id>/web-react/public/bundles/<id>`).

Then:

```bash
bash scripts/ci/sync_web_<id>_bundle.sh
# wire the workspace package if you are checking the shell into this repo
npm run dev
```

Pass criteria (same as kit-runner Web): host **Embedded**; submit a fixed note; runtime-owned title/tags/note type/next action/status; no sidecar URL.

## Validate (this repo, no live `app new`)

```bash
bash scripts/ci/new_app_author_check.sh
```

CI runs that on every PR. It remaps the checked-in `app new` fixture and proves the Web host rewrite. Live `cargo run -p traverse-cli-rs -- app new` still needs `TRAVERSE_REPO` on your machine.

Once the bundle has real components:

```bash
bash scripts/ci/phase2_link_traverse.sh
cargo run -p traverse-cli-rs --manifest-path "$TRAVERSE_REPO/Cargo.toml" -- \
  app validate --manifest "manifests/$APP_ID/app.manifest.json" --json
```

Registration is optional local-dev (`app register`). It is **not** the UI shipping path.

## Do / don’t

| Do | Don’t |
|---|---|
| Remap `manifest.json` → `app.manifest.json` | Treat `app new` output as a runnable product |
| Seed from a primary kit or published `registry_ref` | Compute title/tags/status in React |
| Copy Web from `traverse-starter` | Import private Traverse internals |
| Keep workflow ids that match real WASM | Start `traverse-cli serve` for the OS shell |
| File a Project 2 draft if a step fails | Open a GitHub Issue in App-Refs |

Seven-OS ports of the new id: follow [`add-platform-client.md`](add-platform-client.md) after Web works. MCP catalog is a separate façade.
