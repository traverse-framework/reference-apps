#!/usr/bin/env bash
# Offline structure smoke for the adopted macOS expedition demo.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

required_files=(
  "fixtures/expedition-runtime-session.json"
  "apps/macos-demo/Package.swift"
  "apps/macos-demo/README.md"
  "apps/macos-demo/Sources/TraverseMacOSDemoApp/TraverseMacOSDemoApp.swift"
  "apps/macos-demo/Sources/TraverseMacOSDemoApp/DemoSession.swift"
  "apps/macos-demo/Sources/TraverseMacOSDemoApp/DemoContentView.swift"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "${repo_root}/${file}" ]]; then
    echo "missing macOS demo artifact: ${file}" >&2
    exit 1
  fi
done

grep -q 'import SwiftUI' "${repo_root}/apps/macos-demo/Sources/TraverseMacOSDemoApp/TraverseMacOSDemoApp.swift"
grep -q 'WindowGroup' "${repo_root}/apps/macos-demo/Sources/TraverseMacOSDemoApp/TraverseMacOSDemoApp.swift"
grep -q 'fixtures/expedition-runtime-session.json' \
  "${repo_root}/apps/macos-demo/Sources/TraverseMacOSDemoApp/DemoSession.swift"
grep -q '"status": "completed"' "${repo_root}/fixtures/expedition-runtime-session.json"
grep -q '"state_updates"' "${repo_root}/fixtures/expedition-runtime-session.json"

echo "macOS demo smoke passed"
