#!/usr/bin/env bash
# Fixture-only pin-flip + deprecation outcomes for meeting-notes + loop.
# Ticket: two-app-reuse-lifecycle (Traverse #1168 predecessor slice).
#
# Happy path (default): exit 0 and write evidence.
# Unsupported case: --case unsupported-deprecated-only → exit non-zero.
#
# Explicit non-claims: not production release-train proof; not BundleEmbedder proof.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
FIXTURE_DIR="$REPO_ROOT/scripts/ci/fixtures/two-app-reuse"
LIFECYCLE_DIR="$FIXTURE_DIR/lifecycle"
CATALOG_JSON="$LIFECYCLE_DIR/catalog.json"
SCENARIO_JSON="$LIFECYCLE_DIR/scenario.json"
PIN_JSON="$FIXTURE_DIR/pin.json"
EVIDENCE_OUT="${TWO_APP_REUSE_LIFECYCLE_EVIDENCE:-$LIFECYCLE_DIR/evidence.json}"
CASE="happy"

while [ $# -gt 0 ]; do
  case "$1" in
    --case)
      CASE="${2:?missing --case value}"
      shift 2
      ;;
    *)
      echo "FAIL: unknown arg: $1" >&2
      echo "usage: $0 [--case happy|unsupported-deprecated-only]" >&2
      exit 2
      ;;
  esac
done

for path in "$CATALOG_JSON" "$SCENARIO_JSON" "$PIN_JSON"; do
  if [ ! -f "$path" ]; then
    echo "FAIL: missing $path" >&2
    exit 1
  fi
done

export REPO_ROOT FIXTURE_DIR LIFECYCLE_DIR CATALOG_JSON SCENARIO_JSON PIN_JSON EVIDENCE_OUT CASE

python3 - <<'PY'
import json
import os
import pathlib
import sys

catalog = json.loads(pathlib.Path(os.environ["CATALOG_JSON"]).read_text())
scenario = json.loads(pathlib.Path(os.environ["SCENARIO_JSON"]).read_text())
pin = json.loads(pathlib.Path(os.environ["PIN_JSON"]).read_text())
case = os.environ["CASE"]
evidence_out = pathlib.Path(os.environ["EVIDENCE_OUT"])

SUPPORTED_FLIP = {"advance", "remain"}
SUPPORTED_DEP = set(scenario["deprecation"]["supported_responses"])


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def release(key: str) -> dict:
    releases = catalog.get("releases") or {}
    if key not in releases:
        fail(f"catalog missing release {key!r}")
    return releases[key]


# --- baseline pin must match published execute fixture ---
baseline_key = scenario["baseline_pin"]
target_key = scenario["target_pin"]
baseline = release(baseline_key)
target = release(target_key)

if pin["capability_id"] != catalog["capability_id"]:
    fail("pin.json capability_id != catalog")
if pin["release_version"] != baseline["release_version"]:
    fail("pin.json release_version != scenario baseline")
if pin["digest"] != baseline["digest"]:
    fail("pin.json digest != scenario baseline digest")
if baseline["digest"] != target["digest"]:
    fail(
        "fixture stand-in target must stay digest-compatible with baseline "
        "(App-Refs does not author a new WASM for lifecycle)"
    )
if not target.get("stand_in"):
    fail("target_pin must be marked stand_in=true (fixture-only next pin)")

apps = scenario["apps"]
if apps != ["meeting-notes", "loop"]:
    fail(f"expected apps [meeting-notes, loop], got {apps!r}")

# --- pin flip ---
flip_rows = []
for app_id in apps:
    decision = (scenario.get("pin_flip") or {}).get(app_id)
    if not decision:
        fail(f"missing pin_flip decision for {app_id}")
    choice = decision.get("choice")
    if choice not in SUPPORTED_FLIP:
        fail(f"{app_id} pin_flip.choice={choice!r} not in {sorted(SUPPORTED_FLIP)}")
    from_ver = decision.get("from")
    to_ver = decision.get("to")
    if from_ver != baseline_key:
        fail(f"{app_id} pin_flip.from must be baseline {baseline_key}")
    if choice == "advance":
        if to_ver != target_key:
            fail(f"{app_id} advance must land on target_pin {target_key}")
    elif to_ver != baseline_key:
        fail(f"{app_id} remain must keep baseline {baseline_key}")
    if not decision.get("compatibility_rationale"):
        fail(f"{app_id} missing compatibility_rationale")
    after = release(to_ver)
    flip_rows.append(
        {
            "app_id": app_id,
            "choice": choice,
            "before": {
                "release_version": baseline["release_version"],
                "digest": baseline["digest"],
            },
            "after": {
                "release_version": after["release_version"],
                "digest": after["digest"],
            },
            "compatibility_rationale": decision["compatibility_rationale"],
        }
    )

# --- deprecation handling ---
dep = scenario["deprecation"]
deprecated_key = dep["deprecated_release"]
if deprecated_key != baseline_key:
    fail("deprecation.deprecated_release must equal baseline_pin for this fixture story")
if dep.get("fixture_lifecycle_after") != "deprecated":
    fail("fixture must mark baseline deprecated after the deprecation step")

dep_rows = []
for app_id in apps:
    response = (dep.get("responses") or {}).get(app_id)
    if not response:
        fail(f"missing deprecation response for {app_id}")
    kind = response.get("response")
    if kind not in SUPPORTED_DEP:
        fail(f"{app_id} deprecation response={kind!r} not in {sorted(SUPPORTED_DEP)}")
    resolved = response.get("resolved_pin")
    if kind == "migrate":
        if resolved != target_key:
            fail(f"{app_id} migrate must resolve to {target_key}")
        if release(resolved).get("lifecycle") == "deprecated":
            fail(f"{app_id} migrate resolved a deprecated release")
    elif kind == "continue_pinning":
        if resolved != deprecated_key:
            fail(f"{app_id} continue_pinning must keep {deprecated_key}")
    elif kind == "fail_closed":
        fail(f"{app_id} fail_closed is only valid in the unsupported negative case")
    if not response.get("rationale"):
        fail(f"{app_id} missing deprecation rationale")
    resolved_rel = release(resolved)
    dep_rows.append(
        {
            "app_id": app_id,
            "response": kind,
            "deprecated_release": deprecated_key,
            "resolved_pin": {
                "release_version": resolved_rel["release_version"],
                "digest": resolved_rel["digest"],
                "lifecycle": "deprecated"
                if resolved == deprecated_key
                else resolved_rel.get("lifecycle"),
            },
            "rationale": response["rationale"],
        }
    )

if case == "unsupported-deprecated-only":
    # Negative path: only the deprecated release exists; consumers that refuse
    # continue_pinning / migrate have no supported resolution → fail closed.
    print(
        "FAIL: unsupported deprecated-only resolution "
        "(no active stand-in pin; consumers cannot invent a floating range)",
        file=sys.stderr,
    )
    raise SystemExit(1)

if case != "happy":
    fail(f"unknown case {case!r}")

evidence = {
    "ticket_id": scenario["ticket_id"],
    "upstream": scenario.get("upstream"),
    "scope": catalog["scope"],
    "non_claims": catalog["non_claims"],
    "shared_capability_id": catalog["capability_id"],
    "baseline": {
        "release_version": baseline["release_version"],
        "digest": baseline["digest"],
        "lifecycle_before": baseline["lifecycle"],
        "lifecycle_after_deprecation_step": "deprecated",
    },
    "fixture_target": {
        "release_version": target["release_version"],
        "digest": target["digest"],
        "stand_in": True,
        "note": target.get("note"),
    },
    "pin_flip": flip_rows,
    "deprecation": dep_rows,
    "assert": {
        "both_apps_start_on_baseline": True,
        "per_app_advance_or_remain_recorded": True,
        "deprecation_responses_recorded": True,
        "fixture_only": True,
        "not_production_release_train": True,
        "not_bundle_embedder_host_proof": True,
    },
}

evidence_out.write_text(json.dumps(evidence, indent=2) + "\n")
print(json.dumps(evidence, indent=2))
print(f"OK: two-app reuse lifecycle evidence → {evidence_out}")
PY
