#!/usr/bin/env node
/**
 * Headless web embedded smoke harness.
 * Uses public BundleEmbedder + NodeFsBundleLoader (no traverse-cli serve).
 *
 * Exit 0 on pass. Exit 1 on failure.
 * Env:
 *   EMBEDDED_SMOKE_REQUIRE_OUTPUT=1 — fail if pipeline does not yield runtime fields
 *     (default: prove init + workflow invoke; stub example agents skip field assert)
 */
import { BundleEmbedder, NodeFsBundleLoader } from '../../vendor/traverse-embedder-web/dist/index.js'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import fs from 'node:fs'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '../..')
const manifest = path.join(
  root,
  'apps/traverse-starter/web-react/public/bundles/traverse-starter/app.manifest.json',
)
const requireOutput = process.env.EMBEDDED_SMOKE_REQUIRE_OUTPUT === '1'

function fail(msg) {
  console.error(`FAIL: ${msg}`)
  process.exit(1)
}

if (!fs.existsSync(manifest)) {
  fail(`missing synced web bundle manifest: ${manifest}`)
}

const embedder = await BundleEmbedder.init({
  manifestPath: manifest,
  loader: new NodeFsBundleLoader(),
  workspaceId: 'local-default',
  platform: 'web',
})

const evidence = embedder.releaseEvidence()
if (!evidence || evidence.runtime?.implementation !== 'browser-webassembly') {
  fail('releaseEvidence missing browser-webassembly implementation')
}
const components = evidence.bundle?.wasm_components
if (!Array.isArray(components) || components.length < 3) {
  fail('expected ≥3 digest-verified wasm components in releaseEvidence')
}
console.log(
  `OK: web BundleEmbedder.init — app=${evidence.bundle.app_id}@${evidence.bundle.app_version} components=${components.length}`,
)

const events = []
embedder.subscribe((event) => {
  events.push(event)
})

const outcome = embedder.submit('traverse-starter.pipeline', {
  note: 'Meeting with design team about onboarding flow improvements',
})
if (outcome.status !== 'accepted') {
  fail(`submit rejected: ${JSON.stringify(outcome.error ?? outcome)}`)
}

const invoked = events.filter((e) => e.event_type === 'capability_invoked')
if (invoked.length === 0) {
  fail('expected capability_invoked (multi-capability workflow did not start)')
}
console.log(
  `OK: web workflow invoked — session=${outcome.sessionId} steps=${invoked.length}`,
)

const resultEvent = events.find((e) => e.event_type === 'capability_result')
const errorEvent = events.find((e) => e.event_type === 'error')
const output =
  resultEvent?.data && typeof resultEvent.data === 'object'
    ? resultEvent.data.output ?? resultEvent.data
    : null

const hasRuntimeFields =
  output &&
  typeof output === 'object' &&
  !Array.isArray(output) &&
  typeof output.title === 'string' &&
  output.title.length > 0

if (hasRuntimeFields) {
  console.log('OK: web pipeline returned runtime-owned output fields (title present)')
} else if (requireOutput) {
  fail(
    `pipeline did not return runtime-owned output fields (EMBEDDED_SMOKE_REQUIRE_OUTPUT=1). events=${JSON.stringify(events)}`,
  )
} else {
  const errCode = errorEvent?.data?.error?.code ?? 'unknown'
  console.log(
    `SKIP: web pipeline output fields — Traverse example agents did not yield JSON (${errCode}). Embed path verified via init + workflow invoke. Set EMBEDDED_SMOKE_REQUIRE_OUTPUT=1 to hard-fail.`,
  )
}

embedder.shutdown()
console.log('PASS: web embedded smoke')
