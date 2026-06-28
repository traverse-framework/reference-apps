#!/usr/bin/env bash
# Validates that a PR body contains the required sections.
# Usage: bash scripts/ci/pr_body_check.sh <pr-body-file>
set -euo pipefail

BODY_FILE="${1:-/tmp/pr-body.md}"

if [ ! -f "$BODY_FILE" ]; then
  echo "ERROR: PR body file not found: $BODY_FILE"
  exit 1
fi

FAIL=0

require_section() {
  local section="$1"
  if ! grep -qi "## $section" "$BODY_FILE"; then
    echo "MISSING section: ## $section"
    FAIL=1
  else
    echo "OK: ## $section"
  fi
}

echo "=== PR body check ==="

require_section "Summary"
require_section "Definition of Done"
require_section "Validation"

# Warn (don't fail) if architecture boundary not mentioned for non-docs PRs
if ! grep -qi "architecture\|boundary\|business logic\|runtime" "$BODY_FILE"; then
  echo "WARN: PR body does not mention architecture boundary or runtime — confirm no business logic leaked into UI"
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo "FAIL: PR body is missing required sections."
  echo "Required: ## Summary, ## Definition of Done, ## Validation"
  exit 1
else
  echo "PASS: PR body has required sections."
fi
