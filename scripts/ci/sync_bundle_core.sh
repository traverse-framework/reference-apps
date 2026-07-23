#!/usr/bin/env bash
# Shared digest-pinned bundle sync core for App-References (#174).
#
# Sourced by thin per-platform wrappers (`sync_*_bundle.sh`). Do not invoke
# this file as a standalone CI gate — use the named wrappers so platform
# destinations stay explicit.
#
# Pin source (single contract):
#   $TRAVERSE_REPO/runtime/runtime.wasm
#   $TRAVERSE_REPO/runtime/runtime-release.json   # sha256 must match wasm
#
# App manifests always come from this repo:
#   $REPO_ROOT/manifests/<app_id>/
#
# Optional Traverse example trees (web / WinUI):
#   $TRAVERSE_REPO/examples/<app_id>/
#   $TRAVERSE_REPO/workflows/examples/<app_id>/
#   $TRAVERSE_REPO/contracts/examples/<app_id>/
#
# Public surfaces only — no private Traverse internals.
#
# Usage (from a wrapper):
#   # shellcheck source=scripts/ci/sync_bundle_core.sh
#   source "$(cd "$(dirname "$0")" && pwd)/sync_bundle_core.sh"
#   sync_bundle_init
#   sync_bundle_destination \
#     --dest "$DEST" \
#     --app traverse-starter \
#     --components validate,process,summarize \
#     --manifest-layout root \
#     --runtime required \
#     --traverse-assets required \
#     --label "web starter"
set -euo pipefail

sync_bundle_init() {
  SYNC_BUNDLE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SYNC_BUNDLE_SCRIPT_DIR/../.." && pwd)"
  TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
}

sync_bundle_sha256_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    shasum -a 256 "$file" | awk '{print $1}'
  fi
}

# Verify runtime.wasm bytes match sibling runtime-release.json sha256.
sync_bundle_verify_runtime_digest() {
  local runtime_dir="$1"
  local wasm="$runtime_dir/runtime.wasm"
  local meta="$runtime_dir/runtime-release.json"
  if [ ! -f "$wasm" ] || [ ! -f "$meta" ]; then
    echo "FAIL: missing runtime.wasm or runtime-release.json under $runtime_dir" >&2
    return 1
  fi
  local expected actual
  expected="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["sha256"])' "$meta")"
  actual="$(sync_bundle_sha256_file "$wasm")"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: runtime.wasm digest mismatch under $runtime_dir" >&2
    echo "      expected=$expected" >&2
    echo "      actual=$actual" >&2
    return 1
  fi
  echo "OK: runtime.wasm digest matches runtime-release.json ($expected)"
}

sync_bundle_copy_component_manifests() {
  local manifest_src="$1"
  local dest="$2"
  local components_csv="$3"
  local IFS=','
  local name
  # shellcheck disable=SC2086
  for name in $components_csv; do
    mkdir -p "$dest/components/$name"
    cp "$manifest_src/components/$name/component.manifest.json" \
      "$dest/components/$name/"
  done
}

sync_bundle_copy_manifests_root() {
  local manifest_src="$1"
  local dest="$2"
  local components_csv="$3"
  cp "$manifest_src/app.manifest.json" "$dest/"
  sync_bundle_copy_component_manifests "$manifest_src" "$dest" "$components_csv"
}

sync_bundle_copy_manifests_subdir() {
  local manifest_src="$1"
  local dest="$2"
  mkdir -p "$dest/manifests"
  # Copy manifests only — never follow/copy Phase 2 `_traverse` checkout symlinks.
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude '_traverse' "$manifest_src/" "$dest/manifests/"
  else
    # Fallback without rsync: copy tree then drop symlink if present.
    cp -a "$manifest_src/." "$dest/manifests/"
    rm -f "$dest/manifests/_traverse"
  fi
}

sync_bundle_copy_runtime() {
  local dest="$1"
  local mode="$2" # required|none
  if [ "$mode" = "none" ]; then
    return 0
  fi
  if [ ! -f "$TRAVERSE_REPO/runtime/runtime.wasm" ]; then
    echo "FAIL: TRAVERSE_REPO runtime missing: $TRAVERSE_REPO/runtime/runtime.wasm" >&2
    return 1
  fi
  if [ ! -f "$TRAVERSE_REPO/runtime/runtime-release.json" ]; then
    echo "FAIL: TRAVERSE_REPO runtime missing: $TRAVERSE_REPO/runtime/runtime-release.json" >&2
    return 1
  fi
  mkdir -p "$dest/runtime"
  cp "$TRAVERSE_REPO/runtime/runtime.wasm" "$dest/runtime/"
  cp "$TRAVERSE_REPO/runtime/runtime-release.json" "$dest/runtime/"
  sync_bundle_verify_runtime_digest "$dest/runtime"
}

sync_bundle_copy_traverse_assets() {
  local dest="$1"
  local app_id="$2"
  local mode="$3" # required|optional|none
  if [ "$mode" = "none" ]; then
    return 0
  fi

  local examples="$TRAVERSE_REPO/examples/$app_id"
  local workflows="$TRAVERSE_REPO/workflows/examples/$app_id"
  local contracts="$TRAVERSE_REPO/contracts/examples/$app_id"

  if [ "$mode" = "required" ]; then
    if [ ! -d "$examples" ]; then
      echo "FAIL: TRAVERSE_REPO examples missing: $examples" >&2
      return 1
    fi
    if [ ! -d "$workflows" ]; then
      echo "FAIL: TRAVERSE_REPO workflows missing: $workflows" >&2
      return 1
    fi
    if [ ! -d "$contracts" ]; then
      echo "FAIL: TRAVERSE_REPO contracts missing: $contracts" >&2
      return 1
    fi
  fi

  mkdir -p \
    "$dest/_traverse/examples/$app_id" \
    "$dest/_traverse/workflows/examples/$app_id" \
    "$dest/_traverse/contracts/examples/$app_id"

  if [ -d "$examples" ]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$examples/" "$dest/_traverse/examples/$app_id/"
    else
      cp -a "$examples/." "$dest/_traverse/examples/$app_id/"
    fi
  elif [ "$mode" = "required" ]; then
    echo "FAIL: examples directory vanished: $examples" >&2
    return 1
  fi

  if [ -d "$workflows" ]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$workflows/" "$dest/_traverse/workflows/examples/$app_id/"
    else
      cp -a "$workflows/." "$dest/_traverse/workflows/examples/$app_id/"
    fi
  elif [ "$mode" = "required" ]; then
    echo "FAIL: workflows directory vanished: $workflows" >&2
    return 1
  fi

  if [ -d "$contracts" ]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$contracts/" "$dest/_traverse/contracts/examples/$app_id/"
    else
      cp -a "$contracts/." "$dest/_traverse/contracts/examples/$app_id/"
    fi
  elif [ "$mode" = "required" ]; then
    echo "FAIL: contracts directory vanished: $contracts" >&2
    return 1
  fi
}

# Sync one destination directory. Flags:
#   --dest PATH (required)
#   --app APP_ID (required)
#   --components csv (required when manifest-layout=root)
#   --manifest-layout root|subdir (default: root)
#   --runtime required|none (default: none)
#   --traverse-assets required|optional|none (default: none)
#   --label TEXT (default: bundle)
sync_bundle_destination() {
  local dest="" app_id="" components="" label="bundle"
  local manifest_layout="root" runtime_mode="none" traverse_assets="none"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dest) dest="$2"; shift 2 ;;
      --app) app_id="$2"; shift 2 ;;
      --components) components="$2"; shift 2 ;;
      --manifest-layout) manifest_layout="$2"; shift 2 ;;
      --runtime) runtime_mode="$2"; shift 2 ;;
      --traverse-assets) traverse_assets="$2"; shift 2 ;;
      --label) label="$2"; shift 2 ;;
      *)
        echo "FAIL: unknown sync_bundle_destination flag: $1" >&2
        return 1
        ;;
    esac
  done

  if [ -z "$dest" ] || [ -z "$app_id" ]; then
    echo "FAIL: sync_bundle_destination requires --dest and --app" >&2
    return 1
  fi

  local manifest_src="$REPO_ROOT/manifests/$app_id"
  if [ ! -d "$manifest_src" ]; then
    echo "FAIL: app manifests missing: $manifest_src" >&2
    return 1
  fi

  rm -rf "$dest"
  mkdir -p "$dest"

  case "$manifest_layout" in
    root)
      if [ -z "$components" ]; then
        echo "FAIL: --components required for --manifest-layout root" >&2
        return 1
      fi
      sync_bundle_copy_manifests_root "$manifest_src" "$dest" "$components"
      ;;
    subdir)
      sync_bundle_copy_manifests_subdir "$manifest_src" "$dest"
      ;;
    *)
      echo "FAIL: unknown --manifest-layout=$manifest_layout (use root|subdir)" >&2
      return 1
      ;;
  esac

  sync_bundle_copy_runtime "$dest" "$runtime_mode"
  sync_bundle_copy_traverse_assets "$dest" "$app_id" "$traverse_assets"
  sync_bundle_materialize_registry_refs "$dest" "$app_id"

  echo "OK: synced $label → $dest"
}

# Convert registry_ref-only component manifests in $dest into local wasm_*
# for FetchBundleLoader / embedded hosts that still require wasm_binary_path.
# Canonical source under manifests/ stays registry_ref; destinations materialize.
# Also copies the referenced example WASM + contract into dest/_traverse when missing
# (Android/Swift sync with --traverse-assets none).
sync_bundle_materialize_registry_refs() {
  local dest="$1"
  local app_id="$2"
  REPO_ROOT="$REPO_ROOT" TRAVERSE_REPO="$TRAVERSE_REPO" DEST="$dest" APP_ID="$app_id" python3 - <<'PY'
import hashlib, json, os, pathlib, shutil, sys

dest = pathlib.Path(os.environ["DEST"])
traverse = pathlib.Path(os.environ["TRAVERSE_REPO"])
app_id = os.environ["APP_ID"]

KNOWN = {
    ("traverse-starter", "traverse-starter.process"): {
        "cap": "process",
        "stem": "process-agent",
    },
}

components_root = dest / "components"
if not components_root.is_dir():
    nested = dest / "manifests" / "components"
    # Android/Swift subdir layout: dest/manifests/{app.manifest,components}
    if not nested.is_dir():
        nested = dest / "manifests" / app_id / "components"
    components_root = nested if nested.is_dir() else components_root

if not components_root.is_dir():
    sys.exit(0)

# App root that owns components/ and (materialized) _traverse/
app_root = components_root.parent

for comp_path in sorted(components_root.glob("*/component.manifest.json")):
    data = json.loads(comp_path.read_text())
    ref = data.get("registry_ref")
    if not ref:
        continue
    if data.get("contract_path") or data.get("wasm_binary_path") or data.get("wasm_digest"):
        print(f"FAIL: {comp_path} has registry_ref and local fields (xor violated)", file=sys.stderr)
        sys.exit(1)
    key = (ref.get("namespace"), ref.get("id"))
    mapping = KNOWN.get(key)
    if mapping is None:
        print(f"FAIL: no materialize mapping for registry_ref {key} in {comp_path}", file=sys.stderr)
        sys.exit(1)

    stem = mapping["stem"]
    cap = mapping["cap"]
    abs_wasm = traverse / f"examples/{app_id}/{stem}/artifacts/{stem}.wasm"
    abs_contract = traverse / f"contracts/examples/{app_id}/capabilities/{cap}/contract.json"
    if not abs_wasm.is_file():
        print(f"FAIL: cannot materialize {key}: missing {abs_wasm}", file=sys.stderr)
        sys.exit(1)
    if not abs_contract.is_file():
        print(f"FAIL: cannot materialize {key}: missing {abs_contract}", file=sys.stderr)
        sys.exit(1)

    dest_wasm = app_root / f"_traverse/examples/{app_id}/{stem}/artifacts/{stem}.wasm"
    dest_contract = app_root / f"_traverse/contracts/examples/{app_id}/capabilities/{cap}/contract.json"
    dest_wasm.parent.mkdir(parents=True, exist_ok=True)
    dest_contract.parent.mkdir(parents=True, exist_ok=True)
    if not dest_wasm.is_file() or dest_wasm.read_bytes() != abs_wasm.read_bytes():
        shutil.copyfile(abs_wasm, dest_wasm)
    if not dest_contract.is_file() or dest_contract.read_bytes() != abs_contract.read_bytes():
        shutil.copyfile(abs_contract, dest_contract)

    digest = "sha256:" + hashlib.sha256(dest_wasm.read_bytes()).hexdigest()
    data.pop("registry_ref", None)
    data["contract_path"] = f"../../_traverse/contracts/examples/{app_id}/capabilities/{cap}/contract.json"
    data["wasm_binary_path"] = f"../../_traverse/examples/{app_id}/{stem}/artifacts/{stem}.wasm"
    data["wasm_digest"] = digest
    comp_path.write_text(json.dumps(data, indent=2) + "\n")
    print(f"OK: materialized registry_ref {key[0]}/{key[1]} → {comp_path} ({digest})")
PY
}
