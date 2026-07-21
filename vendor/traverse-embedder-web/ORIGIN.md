# Vendored from traverse-framework/Traverse packages/web/TraverseEmbedder @ 0.7.0 (spec 068).
# Refresh: cd $TRAVERSE_REPO/packages/web/TraverseEmbedder && npm i && npm run build && rsync -a --delete package.json README.md dist/ <App-Refs>/vendor/traverse-embedder-web/
#
# After refresh, re-sync app bundles (web uses example WASM trees, not runtime.wasm):
#   export TRAVERSE_REPO=/path/to/Traverse
#   bash scripts/ci/sync_web_starter_bundle.sh
#   bash scripts/ci/sync_web_doc_approval_bundle.sh
# See docs/runtime-bundle-sync.md for the shared pin contract.
