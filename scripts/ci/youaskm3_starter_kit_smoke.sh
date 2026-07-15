#!/usr/bin/env bash
# Offline smoke for the youaskm3 starter kit (canonical home in reference-apps).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

test -s "${repo_root}/apps/youaskm3-starter-kit/README.md"
test -s "${repo_root}/apps/youaskm3-starter-kit/package.json"
test -s "${repo_root}/docs/youaskm3-starter-kit.md"
test -s "${repo_root}/apps/browser-consumer/index.js"
test -s "${repo_root}/apps/browser-consumer/package.json"

grep -q "youaskm3 Traverse Starter Kit" "${repo_root}/apps/youaskm3-starter-kit/README.md"
grep -q "versioned Traverse consumer bundle" "${repo_root}/apps/youaskm3-starter-kit/README.md"
grep -q "browser-targeted consumer package" "${repo_root}/apps/youaskm3-starter-kit/README.md"
grep -q "youaskm3 Starter Kit and Integration Guide" "${repo_root}/docs/youaskm3-starter-kit.md"
grep -q "apps/browser-consumer" "${repo_root}/docs/youaskm3-starter-kit.md"
grep -q "bash scripts/ci/youaskm3_starter_kit_smoke.sh" "${repo_root}/docs/youaskm3-starter-kit.md"

node -e "const c=require('${repo_root}/apps/browser-consumer'); if(c.APPROVED_BROWSER_CONSUMER_SESSION.title!=='Traverse Browser Consumer') process.exit(1)"

echo "youaskm3 starter kit smoke passed."
