#!/usr/bin/env bash
# Overlay digest-pinned Traverse-published smoke agents + patch digests for embedded E2E.
# - Overwrites TRAVERSE_REPO example *.wasm (CI/local Traverse checkout) with pinned product agents
# - Writes smoke manifest tree under $SMOKE_MANIFEST_DIR (default /tmp)
# - Syncs + patches web public bundle (gitignored)
# Does NOT mutate committed manifests/ in the git worktree.
#
# Pins live in scripts/ci/fixtures/traverse-starter-smoke-agents/ (see digests.json provenance).
# Refresh: bash scripts/ci/pin_traverse_starter_smoke_agents.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
FIXTURE_DIR="$REPO_ROOT/scripts/ci/fixtures/traverse-starter-smoke-agents"
DIGESTS_JSON="$FIXTURE_DIR/digests.json"
SMOKE_MANIFEST_DIR="${SMOKE_MANIFEST_DIR:-/tmp/app-refs-embedded-smoke-manifests}"

if [ ! -f "$DIGESTS_JSON" ]; then
  echo "FAIL: missing $DIGESTS_JSON — run: bash scripts/ci/pin_traverse_starter_smoke_agents.sh"
  exit 1
fi
if [ ! -d "$TRAVERSE_REPO/examples/traverse-starter" ]; then
  echo "FAIL: TRAVERSE_REPO examples missing: $TRAVERSE_REPO"
  exit 1
fi

export REPO_ROOT TRAVERSE_REPO FIXTURE_DIR DIGESTS_JSON SMOKE_MANIFEST_DIR

python3 - <<'PY'
import hashlib, json, pathlib, shutil, re, os

repo = pathlib.Path(os.environ["REPO_ROOT"])
traverse = pathlib.Path(os.environ["TRAVERSE_REPO"])
fixture = pathlib.Path(os.environ["FIXTURE_DIR"])
digests_doc = json.loads(pathlib.Path(os.environ["DIGESTS_JSON"]).read_text())
smoke_root = pathlib.Path(os.environ["SMOKE_MANIFEST_DIR"])

provenance = digests_doc.get("provenance") or {}
if provenance:
    print(
        "OK: agent provenance source=%s ref=%s"
        % (provenance.get("source", "?"), provenance.get("ref", "?")[:12])
    )

mapping = {
    "validate": "validate-agent",
    "process": "process-agent",
    "summarize": "summarize-agent",
}

digests = {}
for key, artifact_stem in mapping.items():
    meta = digests_doc[key]
    src = fixture / meta["file"]
    if not src.is_file():
        raise SystemExit(
            f"FAIL: missing pinned agent {src} — run: bash scripts/ci/pin_traverse_starter_smoke_agents.sh"
        )
    data = src.read_bytes()
    actual = f"sha256:{hashlib.sha256(data).hexdigest()}"
    expected = meta["digest"]
    if actual != expected:
        raise SystemExit(f"FAIL: digest mismatch for {src}: expected {expected} actual {actual}")
    if len(data) < 100:
        raise SystemExit(f"FAIL: pinned agent {src} looks like a stub ({len(data)} bytes)")
    digests[key] = meta
    dest = traverse / f"examples/traverse-starter/{artifact_stem}/artifacts/{artifact_stem}.wasm"
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dest)
    print(f"OK: overlay {dest} ({expected})")

# Smoke manifest tree (copy then patch; skip existing _traverse link/dir)
if smoke_root.exists():
    shutil.rmtree(smoke_root)

def _ignore_traverse(_dir, names):
    return [n for n in names if n == "_traverse"]

shutil.copytree(repo / "manifests/traverse-starter", smoke_root, ignore=_ignore_traverse)

# Materialize registry_ref process → local wasm for CLI smoke host (xor local fields).
process_comp = smoke_root / "components/process/component.manifest.json"
proc = json.loads(process_comp.read_text())
if "registry_ref" in proc:
    stem = "process-agent"
    abs_wasm = traverse / f"examples/traverse-starter/{stem}/artifacts/{stem}.wasm"
    abs_contract = traverse / "contracts/examples/traverse-starter/capabilities/process/contract.json"
    assert abs_wasm.is_file(), abs_wasm
    assert abs_contract.is_file(), abs_contract
    digest = digests["process"]["digest"]
    proc.pop("registry_ref", None)
    proc["contract_path"] = "../../_traverse/contracts/examples/traverse-starter/capabilities/process/contract.json"
    proc["wasm_binary_path"] = f"../../_traverse/examples/traverse-starter/{stem}/artifacts/{stem}.wasm"
    proc["wasm_digest"] = digest
    process_comp.write_text(json.dumps(proc, indent=2) + "\n")
    print(f"OK: smoke materialized process registry_ref → local ({digest})")

for key, component in [("validate", "validate"), ("process", "process"), ("summarize", "summarize")]:
    digest = digests[key]["digest"]
    comp = smoke_root / f"components/{component}/component.manifest.json"
    text = re.sub(r'"wasm_digest"\s*:\s*"[^"]+"', f'"wasm_digest": "{digest}"', comp.read_text(), count=1)
    comp.write_text(text)

app = smoke_root / "app.manifest.json"
app_data = json.loads(app.read_text())
for i, key in enumerate(["validate", "process", "summarize"]):
    app_data["components"][i]["digest"] = digests[key]["digest"]
# Ensure _traverse points at TRAVERSE_REPO for CLI host
link = smoke_root / "_traverse"
if link.exists() or link.is_symlink():
    link.unlink()
link.symlink_to(traverse)
app.write_text(json.dumps(app_data, indent=2) + "\n")
print(f"OK: smoke manifests → {smoke_root}")
print(f"TRAVERSE_STARTER_MANIFEST={smoke_root / 'app.manifest.json'}")
PY

TRAVERSE_REPO="$TRAVERSE_REPO" bash "$REPO_ROOT/scripts/ci/sync_web_starter_bundle.sh"

python3 - <<'PY'
import json, pathlib, re, os
repo = pathlib.Path(os.environ["REPO_ROOT"])
digests_doc = json.loads(pathlib.Path(os.environ["DIGESTS_JSON"]).read_text())
digests = {k: digests_doc[k] for k in ("validate", "process", "summarize")}
bundle = repo / "apps/traverse-starter/web-react/public/bundles/traverse-starter"
for key, component in [("validate", "validate"), ("process", "process"), ("summarize", "summarize")]:
    digest = digests[key]["digest"]
    # Overlay wasm inside synced _traverse tree too
    stem = f"{key}-agent"
    wasm_src = pathlib.Path(os.environ["FIXTURE_DIR"]) / digests[key]["file"]
    wasm_dest = bundle / f"_traverse/examples/traverse-starter/{stem}/artifacts/{stem}.wasm"
    wasm_dest.parent.mkdir(parents=True, exist_ok=True)
    wasm_dest.write_bytes(wasm_src.read_bytes())
    comp = bundle / f"components/{component}/component.manifest.json"
    text = re.sub(r'"wasm_digest"\s*:\s*"[^"]+"', f'"wasm_digest": "{digest}"', comp.read_text(), count=1)
    comp.write_text(text)
app = bundle / "app.manifest.json"
data = json.loads(app.read_text())
for i, key in enumerate(["validate", "process", "summarize"]):
    data["components"][i]["digest"] = digests[key]["digest"]
app.write_text(json.dumps(data, indent=2) + "\n")
print(f"OK: patched web bundle digests + wasm → {bundle}")
PY

# Export path for caller
echo "$SMOKE_MANIFEST_DIR/app.manifest.json" > /tmp/app-refs-smoke-manifest-path.txt
echo "OK: embedded smoke bundle prepared"
