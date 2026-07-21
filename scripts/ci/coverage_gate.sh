#!/usr/bin/env bash
# Coverage gate for non-trivial UI logic.
# Passes when no coverage targets are configured (safe before logic exists).
# Becomes enforcing once targets are added to ci/coverage-targets.txt.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
TARGETS_FILE="$REPO_ROOT/ci/coverage-targets.txt"
THRESHOLD="${COVERAGE_THRESHOLD:-100}"

echo "=== Coverage gate ==="

if [ ! -f "$TARGETS_FILE" ] || [ ! -s "$TARGETS_FILE" ]; then
  echo "PASS: no coverage targets configured — gate is inactive."
  echo "Add target module paths to ci/coverage-targets.txt to activate."
  exit 0
fi

echo "Coverage threshold: ${THRESHOLD}%"
echo "Targets:"
cat "$TARGETS_FILE"
echo ""

# Run tests with coverage
cd "$REPO_ROOT"
npm run test:coverage 2>/dev/null || {
  echo "FAIL: test suite failed."
  exit 1
}

COVERAGE_FILE="$REPO_ROOT/apps/traverse-starter/web-react/coverage/coverage-summary.json"
if [ ! -f "$COVERAGE_FILE" ]; then
  echo "FAIL: coverage output not found at $COVERAGE_FILE"
  exit 1
fi

GATE_FAIL=0

while IFS= read -r target; do
  [[ -z "$target" || "$target" == \#* ]] && continue

  # Extract line coverage % for this target from the JSON summary
  PCT=$(node -e "
    const s = require('$COVERAGE_FILE');
    const key = Object.keys(s).find(k => k.includes('$target'));
    if (!key) { process.stdout.write('NOT_FOUND'); process.exit(0); }
    const lines = s[key].lines;
    process.stdout.write(String(Math.floor(lines.pct)));
  " 2>/dev/null || echo "NOT_FOUND")

  if [ "$PCT" = "NOT_FOUND" ]; then
    echo "WARN: coverage target '$target' not found in coverage report — skipping"
    continue
  fi

  if [ "$PCT" -lt "$THRESHOLD" ]; then
    echo "FAIL: $target — ${PCT}% (threshold: ${THRESHOLD}%)"
    GATE_FAIL=1
  else
    echo "OK:   $target — ${PCT}%"
  fi
done < "$TARGETS_FILE"

echo ""
if [ "$GATE_FAIL" -eq 1 ]; then
  echo "FAIL: one or more targets are below the ${THRESHOLD}% threshold."
  exit 1
else
  echo "PASS: all coverage targets meet the threshold."
fi
