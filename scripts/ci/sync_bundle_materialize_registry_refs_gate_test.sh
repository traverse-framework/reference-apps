#!/usr/bin/env bash
# Assert APP_REFS_MATERIALIZE_REGISTRY_REFS gate for sync_bundle_materialize_registry_refs.
# Does not require TRAVERSE_REPO example trees when materialize is off.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/ci/sync_bundle_core.sh
source "$ROOT/scripts/ci/sync_bundle_core.sh"
sync_bundle_init

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/components/process"
cat >"$TMP/components/process/component.manifest.json" <<'JSON'
{
  "component_id": "test.process-component",
  "version": "1.0.0",
  "schema_version": "1.0.0",
  "capability_id": "meeting-notes.process",
  "capability_version": "1.0.0",
  "registry_ref": {
    "namespace": "meeting-notes",
    "id": "meeting-notes.process",
    "version_range": "^1.0.0"
  }
}
JSON

# Off: destination must keep registry_ref and must not gain wasm_* fields.
APP_REFS_MATERIALIZE_REGISTRY_REFS=0 sync_bundle_materialize_registry_refs "$TMP" "meeting-notes"
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMP/components/process/component.manifest.json")
data = json.loads(p.read_text())
assert "registry_ref" in data, data
assert "wasm_binary_path" not in data and "wasm_digest" not in data, data
print("OK: materialize gate off preserves registry_ref")
PY

echo "PASS: sync_bundle_materialize_registry_refs_gate"
