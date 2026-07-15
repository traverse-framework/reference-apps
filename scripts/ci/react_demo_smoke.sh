#!/usr/bin/env bash
# Offline fixture smoke for the adopted React expedition demo.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
app_dir="$repo_root/apps/react-demo"

test -f "${app_dir}/index.html"
test -f "${app_dir}/public/expedition-runtime-session.json"
test -f "${app_dir}/src/main.js"
test -f "${app_dir}/src/styles.css"
test -f "${app_dir}/vendor/react.development.js"
test -f "${app_dir}/vendor/react-dom.development.js"

grep -q "Traverse React Demo" "${app_dir}/index.html"
grep -q '"status": "completed"' "${app_dir}/public/expedition-runtime-session.json"
grep -q "Submit approved request" "${app_dir}/src/main.js"
grep -q "react.development.js" "${app_dir}/index.html"
grep -q "react-dom.development.js" "${app_dir}/index.html"
node --check "${app_dir}/src/main.js"
node --check "${app_dir}/src/browser-adapter-client.js"

printf 'React demo smoke passed.\n'
