#!/usr/bin/env bash
# Remap `traverse-cli app new` output into App-Refs layout.
#
# CLI scaffold:  apps/<id>/manifest.json  (empty bundle; not a product app)
# App-Refs:      manifests/<id>/app.manifest.json
#
# Does not invent title/tags/status. Does not start traverse-cli serve.
# Optional --seed-from copies a primary kit (components, workflows, state_machine)
# and sets app_id; workflow ids stay those of the seed (reuse published WASM).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/ci/remap_app_new_to_kit.sh --from <cli-app-dir> --out <manifests/app-dir> [options]

Options:
  --from PATH         Directory created by `app new` (contains manifest.json)
  --out PATH          Destination manifests/<app-id>/ directory
  --app-id ID         Override app_id (default: .app_id from the CLI manifest)
  --seed-from NAME    Overlay manifests/<NAME>/ (e.g. traverse-starter), excluding _traverse
  -h, --help

Won’t Fix in this repo: Traverse `app new` filename. See docs/new-app-author.md.
EOF
}

FROM=""
OUT=""
APP_ID=""
SEED=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --app-id) APP_ID="${2:-}"; shift 2 ;;
    --seed-from) SEED="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "FAIL: unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$FROM" ] || [ -z "$OUT" ]; then
  echo "FAIL: --from and --out are required" >&2
  usage
  exit 1
fi

if [ ! -f "$FROM/manifest.json" ]; then
  echo "FAIL: $FROM/manifest.json not found (expected traverse-cli app new output)" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required" >&2
  exit 1
fi

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"

mkdir -p "$OUT"
cp "$FROM/manifest.json" "$OUT/app.manifest.json"
if [ -f "$FROM/workspace.config.json" ]; then
  cp "$FROM/workspace.config.json" "$OUT/workspace.config.json"
fi

if [ -z "$APP_ID" ]; then
  APP_ID="$(jq -r '.app_id' "$OUT/app.manifest.json")"
fi
if [ -z "$APP_ID" ] || [ "$APP_ID" = "null" ]; then
  echo "FAIL: could not determine app_id" >&2
  exit 1
fi

tmp="$(mktemp)"
jq --arg id "$APP_ID" '.app_id = $id' "$OUT/app.manifest.json" >"$tmp"
mv "$tmp" "$OUT/app.manifest.json"

if [ -n "$SEED" ]; then
  SEED_DIR="$REPO_ROOT/manifests/$SEED"
  if [ ! -d "$SEED_DIR" ]; then
    echo "FAIL: seed kit not found: $SEED_DIR" >&2
    exit 1
  fi
  # Overlay kit files; keep destination app_id. Do not follow _traverse symlink.
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude '_traverse' "$SEED_DIR/" "$OUT/"
  else
    # Portable fallback: copy tree then drop a copied _traverse symlink if present
    cp -R "$SEED_DIR/." "$OUT/"
    rm -f "$OUT/_traverse"
  fi
  tmp="$(mktemp)"
  jq --arg id "$APP_ID" '.app_id = $id' "$OUT/app.manifest.json" >"$tmp"
  mv "$tmp" "$OUT/app.manifest.json"
  # CLI workspace.config.json must not override seeded kit defaults.
  if [ ! -f "$SEED_DIR/workspace.config.json" ]; then
    rm -f "$OUT/workspace.config.json"
  fi
fi

echo "OK: remapped $FROM/manifest.json -> $OUT/app.manifest.json (app_id=$APP_ID${SEED:+ seed=$SEED})"
