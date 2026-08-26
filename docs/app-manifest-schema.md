# Application bundle manifest (`app.manifest.json`)

**Audience:** authors packaging a capability so a public embedder (Web / Rust / Swift / .NET / Kotlin) can load and run it.

**Architecture boundary:** this file declares *which* WASM components and workflows the app ships. It does **not** contain business logic. Title, tags, recommendations, and other product fields come from runtime-owned WASM output — the UI only renders them.

Governing Traverse spec: [`044-application-bundle-manifest`](https://github.com/traverse-framework/Traverse/blob/main/specs/044-application-bundle-manifest/spec.md) (schema `1.0.0`).

Related App-Refs docs: [`production-packaging.md`](production-packaging.md) · [`runtime-bundle-sync.md`](runtime-bundle-sync.md) · [`getting-started-embedded.md`](getting-started-embedded.md) · [`kit-runner-persona.md`](kit-runner-persona.md)

---

## Why this exists

A capability-level `agent_package` manifest is not enough for embedders. An **application bundle** adds:

- App identity + version
- Concrete component references (local digests and/or `registry_ref`)
- Workflow wiring
- Placement / public surfaces
- Optional **state machine** for submit → processing → results UX
- Config schema + defaults (workspace-local overrides stay out of the governed manifest)

Without this file, `BundleEmbedder` / `traverse-embedder` have nothing to load.

---

## Where App-Refs keeps manifests

| Layout | Path | Notes |
|---|---|---|
| **App-Refs (checked in)** | `manifests/<app>/app.manifest.json` | Filename is **`app.manifest.json`** |
| Component manifests | `manifests/<app>/components/<name>/component.manifest.json` | Referenced via `manifest_path` |
| Traverse examples | `$TRAVERSE_REPO/examples/applications/<app>/app.manifest.json` | Upstream reference copies |
| CLI scaffold (see below) | `apps/<app-id>/manifest.json` | Different **filename** and directory |

Reference implementations in this repo: `manifests/traverse-starter/`, `manifests/doc-approval/`, `manifests/meeting-notes/`, `manifests/loop/`.

---

## Top-level fields (`schema_version` `1.0.0`)

Minimum fields from Traverse FR-001 (spec 044):

| Field | Type | Role |
|---|---|---|
| `app_id` | string | Stable app identity (e.g. `traverse-starter`) |
| `version` | semver string | App bundle version |
| `schema_version` | string | Manifest schema (`1.0.0`) |
| `workspace_defaults` | object | Default `workspace_id` / registry scope / optional `config_path` |
| `components` | array | Concrete component entries (see below) |
| `workflows` | array | Workflow id + version + path to workflow JSON |
| `model_dependencies` | array | Usually `[]` for deterministic demos |
| `config_schema` | JSON Schema | Governed config shape |
| `default_config` | object | Safe defaults matching `config_schema` |
| `placement_policy` | object | e.g. `preferred_targets: ["local"]`, optional `allow_fallback` |
| `public_surfaces` | string[] | e.g. `["cli", "http_json"]` |

### App-Refs additions (used by primary shells)

| Field | Role |
|---|---|
| `state_machine` | Declares UI-relevant states (`idle` → `processing` → `results` / `error`), `invoke.capability_id`, and `list_context_fields` for runtime-owned output paths |

`state_machine` is **optional** for a schema-valid empty scaffold, but **required in practice** for App-Refs primary shells that drive submit/result UX from runtime events. Spec 044 focuses on identity/components/workflows; App-Refs examples always include a state machine.

### `components[]` entry

Each entry is a **concrete** reference (no version ranges for substitution — FR-003):

| Field | Role |
|---|---|
| `component_id` | Component identity |
| `version` | Component version |
| `digest` | `sha256:…` of the component artifact (must match component manifest / resolved bytes) |
| `manifest_path` | Relative path to `component.manifest.json` |

### Component manifest (sibling file)

Two mutually exclusive wiring styles (xor):

1. **Local paths** — `contract_path`, `wasm_binary_path`, `wasm_digest`
2. **`registry_ref`** — `{ namespace, id, version_range }` (App-Refs process component uses this; sync materializes local wasm for embedder trees — see [`production-packaging.md`](production-packaging.md))

Also required on the component manifest: `capability_id`, `capability_version`, `runtime_constraints`, `permitted_targets`, `dependencies`, `connector_requirements`, `validation_evidence`.

---

## Minimal annotated shape

```json
{
  "app_id": "my-app",
  "version": "1.0.0",
  "schema_version": "1.0.0",
  "workspace_defaults": {
    "workspace_id": "local-default",
    "registry_scope": "private"
  },
  "components": [
    {
      "component_id": "my-app.process-component",
      "version": "1.0.0",
      "digest": "sha256:…",
      "manifest_path": "components/process/component.manifest.json"
    }
  ],
  "workflows": [
    {
      "workflow_id": "my-app.process",
      "workflow_version": "1.0.0",
      "path": "_traverse/workflows/…/workflow.json"
    }
  ],
  "model_dependencies": [],
  "config_schema": { "type": "object", "additionalProperties": false, "properties": {} },
  "default_config": {},
  "placement_policy": { "preferred_targets": ["local"], "allow_fallback": false },
  "public_surfaces": ["cli", "http_json"],
  "state_machine": {
    "initial_state": "idle",
    "list_context_fields": ["output.…"],
    "states": [ /* idle / processing / results / error */ ]
  }
}
```

Copy a full working example from `manifests/traverse-starter/app.manifest.json` rather than inventing field names.

---

## `traverse-cli app new` — what it scaffolds today

Verified against Traverse `traverse-cli` (`app new` / `app_new_at`):

```bash
# From an empty working directory (creates apps/<app-id>/ under cwd)
traverse-cli app new <app-id>
# Optional: --register --workspace <workspace-id>  (fails until real components exist)
```

### Output tree

```text
apps/<app-id>/
  manifest.json              # ← not named app.manifest.json
  workspace.config.json
  README.md
  components/README.md       # placeholder only
  workflows/README.md        # placeholder only
```

### Generated `manifest.json` contents

Schema-valid **empty** bundle:

- `components: []`, `workflows: []`, `model_dependencies: []`
- `placement_policy.preferred_targets: ["local"]`
- `public_surfaces: ["cli"]`
- `workspace_defaults.workspace_id: "<app-id>-local"` + `config_path: "workspace.config.json"`
- **No** `state_machine`
- **No** WASM / digests / fake product behavior (spec 044 QG-004)

`--register` attempts validation/registration after generation; incomplete scaffolds must fail with a clear validation result (FR-016).

### Scaffold → App-Refs layout

| CLI scaffold | App-Refs convention |
|---|---|
| `apps/<id>/manifest.json` | `manifests/<id>/app.manifest.json` |
| empty `components/` | real `components/<name>/component.manifest.json` + digests |
| empty `workflows/` | workflow JSON under `_traverse/…` (or synced Traverse tree) |
| no state machine | add `state_machine` + `list_context_fields` for UI shells |

Then sync into platform bundles with `scripts/ci/sync_*_bundle.sh` ([`runtime-bundle-sync.md`](runtime-bundle-sync.md)).

---

## Validate / register (Phase 2 CLI)

Once the bundle has real components:

```bash
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/phase2_link_traverse.sh
cargo run -p traverse-cli-rs --manifest-path "$TRAVERSE_REPO/Cargo.toml" -- \
  app validate --manifest manifests/traverse-starter/app.manifest.json --json
```

Registration is workspace-persisted (`app register --workspace …`). Primary shipping path for UIs remains **embedded** load of the bundle — not `traverse-cli serve`.

---

## Do / don’t

| Do | Don’t |
|---|---|
| Point digests at real Traverse-published WASM | Invent title/tags/status in the UI or in scaffold READMEs |
| Keep business rules in WASM agents | Treat `app new` output as a runnable product app |
| Use public embedder SDKs only | Import private Traverse crates into App-Refs UI code |
