#!/usr/bin/env bash
# Refresh digest-pinned Traverse-published traverse-starter agents into
# scripts/ci/fixtures/traverse-starter-smoke-agents/.
#
# Requires TRAVERSE_REPO with real (non-stub) example agents.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRAVERSE_REPO="${TRAVERSE_REPO:-$REPO_ROOT/../Traverse}"
OUT_DIR="$REPO_ROOT/scripts/ci/fixtures/traverse-starter-smoke-agents"

if [ ! -d "$TRAVERSE_REPO/examples/traverse-starter" ]; then
  echo "FAIL: TRAVERSE_REPO examples missing: $TRAVERSE_REPO"
  exit 1
fi

export REPO_ROOT TRAVERSE_REPO OUT_DIR

python3 - <<'PY'
import hashlib, json, pathlib, os, subprocess

traverse = pathlib.Path(os.environ["TRAVERSE_REPO"])
out = pathlib.Path(os.environ["OUT_DIR"])
out.mkdir(parents=True, exist_ok=True)

mapping = {
    "validate": "validate-agent",
    "process": "process-agent",
    "summarize": "summarize-agent",
}

try:
    ref = subprocess.check_output(
        ["git", "-C", str(traverse), "rev-parse", "HEAD"],
        text=True,
    ).strip()
except subprocess.CalledProcessError as exc:
    raise SystemExit(f"FAIL: cannot resolve Traverse HEAD: {exc}") from exc

agents = {}
for key, stem in mapping.items():
    src = traverse / f"examples/traverse-starter/{stem}/artifacts/{stem}.wasm"
    if not src.is_file():
        raise SystemExit(f"FAIL: missing Traverse agent: {src}")
    data = src.read_bytes()
    if len(data) < 100:
        raise SystemExit(
            f"FAIL: {src} looks like a stub ({len(data)} bytes). "
            "Checkout Traverse main with real stdout agents (#795/#803/#805/#809)."
        )
    digest = f"sha256:{hashlib.sha256(data).hexdigest()}"
    dest = out / f"{stem}.wasm"
    dest.write_bytes(data)
    agents[key] = {
        "file": dest.name,
        "digest": digest,
        "bytes": len(data),
        "traverse_source": f"examples/traverse-starter/{stem}/artifacts/{stem}.wasm",
    }
    print(f"OK: pinned {dest.name} {digest} ({len(data)} bytes)")

payload = {
    "provenance": {
        "source": "traverse-framework/Traverse",
        "ref": ref,
        "note": (
            "Digest-pinned copies of Traverse-published traverse-starter example "
            "agents (stdout-only WASM). Not App-Refs hand-built WASI stand-ins. "
            "Refresh with: bash scripts/ci/pin_traverse_starter_smoke_agents.sh"
        ),
    },
    **agents,
}
(out / "digests.json").write_text(json.dumps(payload, indent=2) + "\n")
print(f"OK: wrote {out / 'digests.json'} (Traverse ref={ref})")
PY
