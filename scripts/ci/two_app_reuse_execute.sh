#!/usr/bin/env bash
# Execute meeting-notes + loop against the same pinned meeting-notes.process 1.3.2 artifact.
# Ticket: two-app-reuse-execute / two-app-reuse-execute-ci (Traverse #1168).
#
# Prepare from the checked-in published fixture only — do not require TRAVERSE_REPO
# example trees (CI native-linux checks out Traverse v0.8.2, which has no core-* WASM).
# Then execute both dest copies with wasmtime. Fails closed if the pin is missing
# or the two consumers disagree.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
PREP="${TWO_APP_REUSE_PREP:-/tmp/app-refs-two-app-reuse}"
FIXTURE_DIR="$REPO_ROOT/scripts/ci/fixtures/two-app-reuse"
PIN_JSON="$FIXTURE_DIR/pin.json"
TRANSCRIPT="${TWO_APP_REUSE_TRANSCRIPT:-Bob will send the report by Friday. Alice decided we should ship next week.}"
EVIDENCE_OUT="${TWO_APP_REUSE_EVIDENCE:-$PREP/evidence.json}"

if [ ! -f "$PIN_JSON" ]; then
  echo "FAIL: missing $PIN_JSON" >&2
  exit 1
fi
if ! command -v wasmtime >/dev/null 2>&1; then
  echo "FAIL: wasmtime is required to execute the published WASI artifact" >&2
  echo "      install: https://wasmtime.dev/ (CI uses bytecodealliance/actions/wasmtime/setup)" >&2
  exit 1
fi

export REPO_ROOT PREP FIXTURE_DIR PIN_JSON TRANSCRIPT EVIDENCE_OUT

python3 - <<'PY'
import hashlib, json, os, shutil, pathlib

repo = pathlib.Path(os.environ["REPO_ROOT"])
prep = pathlib.Path(os.environ["PREP"])
fixture_dir = pathlib.Path(os.environ["FIXTURE_DIR"])
pin = json.loads(pathlib.Path(os.environ["PIN_JSON"]).read_text())
wasm_src = fixture_dir / pin["file"]
contract_src = fixture_dir / pin.get("contract_file", "meeting-notes.process-1.3.2.contract.json")
if not wasm_src.is_file():
    raise SystemExit(f"FAIL: missing fixture {wasm_src}")
if not contract_src.is_file():
    raise SystemExit(f"FAIL: missing contract fixture {contract_src}")
data = wasm_src.read_bytes()
digest = "sha256:" + hashlib.sha256(data).hexdigest()
if digest != pin["digest"]:
    raise SystemExit(f"FAIL: fixture digest {digest} != {pin['digest']}")
if len(data) < 1000:
    raise SystemExit(f"FAIL: fixture looks like a stub ({len(data)} bytes)")

if prep.exists():
    shutil.rmtree(prep)
prep.mkdir(parents=True)

SHARED = ("meeting-notes", "meeting-notes.process")


def materialize(app_id: str) -> pathlib.Path:
    dest = prep / app_id
    shutil.copytree(repo / "manifests" / app_id, dest, ignore=shutil.ignore_patterns("_traverse"))
    components_root = dest / "components"
    prepared = 0
    for comp_path in sorted(components_root.glob("*/component.manifest.json")):
        payload = json.loads(comp_path.read_text())
        ref = payload.get("registry_ref") or {}
        key = (ref.get("namespace"), ref.get("id"))
        if key != SHARED:
            continue
        dest_rel_wasm = "_traverse-cache/meeting-notes.process.wasm"
        dest_rel_contract = "_traverse-cache/meeting-notes.process.contract.json"
        dest_wasm = dest / dest_rel_wasm
        dest_contract = dest / dest_rel_contract
        dest_wasm.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(wasm_src, dest_wasm)
        shutil.copyfile(contract_src, dest_contract)
        wasm_digest = "sha256:" + hashlib.sha256(dest_wasm.read_bytes()).hexdigest()
        if wasm_digest != pin["digest"]:
            raise SystemExit(f"FAIL: {app_id} shared wasm digest {wasm_digest} != pin")
        rel_from_comp = pathlib.Path(os.path.relpath(dest_wasm, comp_path.parent)).as_posix()
        rel_contract_from_comp = pathlib.Path(os.path.relpath(dest_contract, comp_path.parent)).as_posix()
        payload.pop("registry_ref", None)
        payload["contract_path"] = rel_contract_from_comp
        payload["wasm_binary_path"] = rel_from_comp
        payload["wasm_digest"] = wasm_digest
        payload["capability_version"] = pin["release_version"]
        comp_path.write_text(json.dumps(payload, indent=2) + "\n")
        prepared += 1
        print(f"OK: prepared {app_id} {key[1]} {wasm_digest}")
    if prepared != 1:
        raise SystemExit(f"FAIL: {app_id} expected 1 shared component, prepared {prepared}")
    return dest

mn = materialize("meeting-notes")
loop = materialize("loop")
(prep / "prepare-meta.json").write_text(
    json.dumps(
        {
            "pin": pin,
            "meeting_notes_manifest": str(mn / "app.manifest.json"),
            "loop_manifest": str(loop / "app.manifest.json"),
        },
        indent=2,
    )
    + "\n"
)
print("OK: prepare complete (fixture-only; no TRAVERSE_REPO examples)")
PY

echo "=== execute prepared meeting-notes.process (meeting-notes dest) ==="
printf '%s' "{\"transcript\":$(python3 -c 'import json,os; print(json.dumps(os.environ["TRANSCRIPT"]))')}" \
  | wasmtime run "$PREP/meeting-notes/_traverse-cache/meeting-notes.process.wasm" \
  > "$PREP/meeting-notes.execute.json"

echo "=== execute prepared meeting-notes.process (loop dest) ==="
printf '%s' "{\"transcript\":$(python3 -c 'import json,os; print(json.dumps(os.environ["TRANSCRIPT"]))')}" \
  | wasmtime run "$PREP/loop/_traverse-cache/meeting-notes.process.wasm" \
  > "$PREP/loop.execute.json"

python3 - <<'PY'
import hashlib, json, os, pathlib

prep = pathlib.Path(os.environ["PREP"])
pin = json.loads(pathlib.Path(os.environ["PIN_JSON"]).read_text())
mn = json.loads((prep / "meeting-notes.execute.json").read_text())
loop_out = json.loads((prep / "loop.execute.json").read_text())
mn_app = json.loads((prep / "meeting-notes" / "app.manifest.json").read_text())
loop_app = json.loads((prep / "loop" / "app.manifest.json").read_text())
if mn != loop_out:
    raise SystemExit("FAIL: consumers produced different output from the shared artifact")

def wasm_digest(app_id: str) -> str:
    path = prep / app_id / "_traverse-cache" / "meeting-notes.process.wasm"
    return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()

mn_digest = wasm_digest("meeting-notes")
loop_digest = wasm_digest("loop")
if mn_digest != pin["digest"] or loop_digest != pin["digest"]:
    raise SystemExit(f"FAIL: digest mismatch mn={mn_digest} loop={loop_digest} pin={pin['digest']}")

mn_blob = json.dumps(mn)
if "Bob" not in mn_blob:
    raise SystemExit("FAIL: output does not reflect transcript (possible 1.0.1 fixture)")

evidence = {
    "ticket_id": "two-app-reuse-execute",
    "upstream": "https://github.com/traverse-framework/Traverse/issues/1168",
    "shared": {
        "capability_id": pin["capability_id"],
        "release_version": pin["release_version"],
        "contract_schema_version": pin["contract_schema_version"],
        "digest": pin["digest"],
        "registry_source": pin["provenance"]["source"],
        "artifact_url": pin["artifact_url"],
    },
    "consumers": [
        {
            "app_id": mn_app.get("app_id"),
            "app_version": mn_app.get("version"),
            "manifest": "manifests/meeting-notes/app.manifest.json",
            "host_path": "manifests/meeting-notes prepare → wasmtime WASI (published 1.3.2 bytes)",
            "workflow_id": "meeting-notes.process",
            "digest": mn_digest,
            "output": mn,
        },
        {
            "app_id": loop_app.get("app_id"),
            "app_version": loop_app.get("version"),
            "manifest": "manifests/loop/app.manifest.json",
            "host_path": "manifests/loop prepare → wasmtime WASI (published 1.3.2 bytes)",
            "workflow_id": "loop.wf1 ingest = meeting-notes.process",
            "digest": loop_digest,
            "output": loop_out,
        },
    ],
    "assert": {
        "capability_id_equal": True,
        "release_version_equal": True,
        "contract_schema_version_equal": True,
        "digest_equal": mn_digest == loop_digest == pin["digest"],
    },
}
out = pathlib.Path(os.environ["EVIDENCE_OUT"])
out.write_text(json.dumps(evidence, indent=2) + "\n")
print(json.dumps(evidence, indent=2))
print(f"OK: evidence {out}")
PY
