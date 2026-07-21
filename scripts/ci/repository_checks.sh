#!/usr/bin/env bash
# Validates required repo structure and governance files.
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
FAIL=0

check() {
  local path="$1"
  local label="$2"
  if [ ! -e "$REPO_ROOT/$path" ]; then
    echo "MISSING: $label ($path)"
    FAIL=1
  else
    echo "OK:      $label"
  fi
}

echo "=== Repository checks ==="

# Governance files
check "CLAUDE.md"                               "CLAUDE.md"
check "AGENTS.md"                               "AGENTS.md"
check ".specify/memory/constitution.md"         "Constitution"
check "docs/quality-standards.md"              "Quality standards"
check "docs/ticket-standard.md"               "Ticket standard"
check "docs/multi-thread-workflow.md"          "Multi-thread workflow"
check "docs/traverse-starter-plan.md"          "traverse-starter plan"
check "docs/traverse-runtime.md"               "Traverse runtime setup"
check "docs/design-language.md"                "UI design language"
check "docs/runtime-bundle-sync.md"            "Runtime bundle sync contract"
check "docs/add-platform-client.md"            "Add platform client recipe"

# Platform clients
check "apps/traverse-starter/ios-swift/TraverseStarter.xcodeproj" "ios-swift Xcode project"
check "apps/traverse-starter/ios-swift/README.md"                 "ios-swift README"
check "apps/traverse-starter/macos-swift/TraverseStarterMac.xcodeproj" "macos-swift Xcode project"
check "apps/traverse-starter/macos-swift/README.md"                    "macos-swift README"
check "apps/traverse-starter/android-compose/settings.gradle.kts"      "android-compose Gradle project"
check "apps/traverse-starter/android-compose/README.md"                "android-compose README"
check "apps/traverse-starter/windows-winui/TraverseStarter.sln"        "windows-winui solution"
check "apps/traverse-starter/windows-winui/README.md"                  "windows-winui README"
check "apps/traverse-starter/linux-gtk/Cargo.toml"                      "linux-gtk Cargo project"
check "apps/traverse-starter/linux-gtk/README.md"                       "linux-gtk README"
check "apps/traverse-starter/cli-rust/Cargo.toml"                       "cli-rust Cargo project"
check "apps/traverse-starter/cli-rust/README.md"                        "cli-rust README"
check "apps/traverse-starter/traverse-core-rs/Cargo.toml"               "traverse-core-rs Cargo crate"
check "apps/traverse-starter/Cargo.toml"                               "traverse-starter Cargo workspace"

# doc-approval clients
check "apps/doc-approval/web-react/package.json"                        "doc-approval web-react package"
check "apps/doc-approval/web-react/README.md"                           "doc-approval web-react README"
check "apps/doc-approval/ios-swift/DocApproval.xcodeproj"               "doc-approval ios-swift Xcode project"
check "apps/doc-approval/ios-swift/README.md"                           "doc-approval ios-swift README"
check "apps/doc-approval/macos-swift/DocApprovalMac.xcodeproj"          "doc-approval macos-swift Xcode project"
check "apps/doc-approval/macos-swift/README.md"                         "doc-approval macos-swift README"
check "apps/doc-approval/android-compose/settings.gradle.kts"           "doc-approval android-compose Gradle project"
check "apps/doc-approval/android-compose/README.md"                     "doc-approval android-compose README"
check "apps/doc-approval/windows-winui/DocApproval.sln"                 "doc-approval windows-winui solution"
check "apps/doc-approval/windows-winui/README.md"                         "doc-approval windows-winui README"
check "apps/doc-approval/linux-gtk/Cargo.toml"                            "doc-approval linux-gtk Cargo project"
check "apps/doc-approval/linux-gtk/README.md"                             "doc-approval linux-gtk README"
check "apps/doc-approval/cli-rust/Cargo.toml"                             "doc-approval cli-rust Cargo project"
check "apps/doc-approval/cli-rust/README.md"                              "doc-approval cli-rust README"
check "apps/doc-approval/DocApprovalCore/Package.swift"                   "doc-approval DocApprovalCore package"
check "apps/doc-approval/doc-approval-core-rs/Cargo.toml"                 "doc-approval-core-rs Cargo crate"
check "apps/doc-approval/Cargo.toml"                                      "doc-approval Cargo workspace"

# Application manifests
check "manifests/traverse-starter/app.manifest.json"                      "traverse-starter app manifest"
check "manifests/doc-approval/app.manifest.json"                          "doc-approval app manifest"
check "manifests/doc-approval/components/analyze/component.manifest.json" "doc-approval analyze component"
check "manifests/doc-approval/components/recommend/component.manifest.json" "doc-approval recommend component"

# meeting-notes clients
check "apps/meeting-notes/web-react/package.json"                       "meeting-notes web-react package"
check "apps/meeting-notes/web-react/README.md"                          "meeting-notes web-react README"

# Adopted Traverse platform demos / starter (issue #151)
check "apps/android-demo/README.md"                                     "android-demo README"
check "apps/android-demo/app/src/main/java/com/traverse/demo/android/MainActivity.kt" "android-demo MainActivity"
check "apps/browser-consumer/index.js"                                  "browser-consumer package"
check "apps/macos-demo/Package.swift"                                   "macos-demo Package.swift"
check "apps/react-demo/src/main.js"                                     "react-demo main"
check "apps/youaskm3-starter-kit/README.md"                             "youaskm3 starter kit"
check "fixtures/expedition-runtime-session.json"                        "expedition runtime fixture"
check "docs/adopted-platform-clients.md"                                "adopted platform clients doc"
check "docs/production-playbook.md"                                     "production playbook"
check "docs/youaskm3-starter-kit.md"                                    "youaskm3 starter guide"
check "scripts/ci/android_demo_smoke.sh"                                "android demo smoke"
check "scripts/ci/macos_demo_smoke.sh"                                  "macos demo smoke"
check "scripts/ci/react_demo_smoke.sh"                                  "react demo smoke"
check "scripts/ci/youaskm3_starter_kit_smoke.sh"                        "youaskm3 starter smoke"
check "scripts/ci/react_demo_live_adapter_smoke.sh"                     "react demo live smoke"
check "scripts/ci/browser_consumer_package_smoke.sh"                    "browser consumer live smoke"

# CI scripts
check "scripts/ci/repository_checks.sh"        "This script"
check "scripts/ci/pr_body_check.sh"            "PR body check"
check "scripts/ci/coverage_gate.sh"            "Coverage gate"
check "scripts/ci/phase1_smoke.sh"             "Phase 1 smoke"
check "scripts/ci/phase2_smoke.sh"             "Phase 2 smoke"
check "scripts/ci/phase2_link_traverse.sh"     "Phase 2 Traverse link"
check "scripts/ci/embedded_smoke.sh"           "Embedded runtime smoke"
check "scripts/ci/embedded_smoke_web.mjs"      "Embedded web smoke harness"
check "scripts/ci/sync_bundle_core.sh"         "Shared bundle sync core"
check "scripts/ci/sync_web_starter_bundle.sh"  "Web starter bundle sync"
check "scripts/ci/sync_web_doc_approval_bundle.sh" "Web doc-approval bundle sync"
check "scripts/ci/sync_winui_starter_bundle.sh" "WinUI starter bundle sync"
check "scripts/ci/sync_winui_doc_approval_bundle.sh" "WinUI doc-approval bundle sync"
check "scripts/ci/sync_swift_starter_bundle.sh" "Swift starter bundle sync"
check "scripts/ci/sync_swift_doc_approval_bundle.sh" "Swift doc-approval bundle sync"
check "scripts/ci/sync_android_starter_bundle.sh" "Android starter bundle sync"
check "scripts/ci/sync_android_doc_approval_bundle.sh" "Android doc-approval bundle sync"
check "scripts/ci/onboarding_check.sh"         "Onboarding check"

# GitHub Actions
check ".github/workflows/ci.yml"               "CI workflow"
check ".github/workflows/nightly.yml"          "Nightly workflow"

# Skill
check ".agents/skills/app-refs-ops/SKILL.md"  "app-refs-ops skill"

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo "FAIL: one or more required files are missing."
  exit 1
else
  echo "PASS: all required files present."
fi
