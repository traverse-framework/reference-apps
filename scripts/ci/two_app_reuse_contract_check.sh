#!/usr/bin/env bash
# Local boundary check for docs/two-app-reuse-contract.md (ticket two-app-reuse-contract).
# Does not require network or TRAVERSE_REPO. Does not require meeting-notes to be realigned
# yet — that is #282. Fails if app identities collapse or a source manifest embeds local WASM.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
FAIL=0

fail() {
  echo "FAIL: $1" >&2
  FAIL=1
}

DOC="$REPO_ROOT/docs/two-app-reuse-contract.md"
MN_APP="$REPO_ROOT/manifests/meeting-notes/app.manifest.json"
LOOP_APP="$REPO_ROOT/manifests/loop/app.manifest.json"
MN_COMP="$REPO_ROOT/manifests/meeting-notes/components/process/component.manifest.json"
LOOP_COMP="$REPO_ROOT/manifests/loop/components/process/component.manifest.json"

PIN_ID="meeting-notes.process"
PIN_VER="1.3.2"
PIN_SCHEMA="1.0.0"
PIN_DIGEST="sha256:ec192a0c2104b08bee76418c5c6d44358036568d655d8465e506858d1aaadbf2"

for path in "$DOC" "$MN_APP" "$LOOP_APP" "$MN_COMP" "$LOOP_COMP"; do
  if [ ! -f "$path" ]; then
    fail "missing $path"
  fi
done

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi

for needle in "$PIN_ID" "$PIN_VER" "$PIN_SCHEMA" "$PIN_DIGEST"; do
  if ! grep -q -F "$needle" "$DOC"; then
    fail "decision record missing pin field: $needle"
  fi
done

python3 - <<PY
import json, sys
from pathlib import Path

root = Path("$REPO_ROOT")
mn_app = json.loads((root / "manifests/meeting-notes/app.manifest.json").read_text())
loop_app = json.loads((root / "manifests/loop/app.manifest.json").read_text())
mn_comp = json.loads((root / "manifests/meeting-notes/components/process/component.manifest.json").read_text())
loop_comp = json.loads((root / "manifests/loop/components/process/component.manifest.json").read_text())

failed = 0

def fail(msg: str) -> None:
    global failed
    print(f"FAIL: {msg}", file=sys.stderr)
    failed = 1

if mn_app.get("app_id") != "meeting-notes":
    fail(f"meeting-notes app_id={mn_app.get('app_id')!r}")
if loop_app.get("app_id") != "loop":
    fail(f"loop app_id={loop_app.get('app_id')!r}")
if mn_app.get("app_id") == loop_app.get("app_id"):
    fail("apps must keep distinct app_id values")

for name, comp in (("meeting-notes", mn_comp), ("loop", loop_comp)):
    if comp.get("capability_id") != "meeting-notes.process":
        fail(f"{name} capability_id={comp.get('capability_id')!r}")
    ref = comp.get("registry_ref") or {}
    if ref.get("namespace") != "meeting-notes" or ref.get("id") != "meeting-notes.process":
        fail(f"{name} registry_ref={ref!r}")
    for local in ("contract_path", "wasm_binary_path", "wasm_digest"):
        if comp.get(local):
            fail(f"{name} source component has local {local}")

def component_digest(app: dict, component_id: str):
    for component in app.get("components") or []:
        if component.get("component_id") == component_id:
            return component.get("digest")
    return None

for name, app, component_id, ref in (
    ("meeting-notes", mn_app, "meeting-notes.process-component", mn_comp),
    ("loop", loop_app, "loop.process-component", loop_comp),
):
    digest = component_digest(app, component_id)
    if digest != "$PIN_DIGEST":
        fail(f"{name} app digest {digest!r} != required pin")
    if ref.get("capability_version") != "1.3.2":
        fail(f"{name} capability_version={ref.get('capability_version')!r}")
    if (ref.get("registry_ref") or {}).get("version_range") != "1.3.2":
        fail(f"{name} version_range={(ref.get('registry_ref') or {}).get('version_range')!r}")

if failed:
    sys.exit(1)
print("OK: two-app reuse contract boundaries")
PY

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
