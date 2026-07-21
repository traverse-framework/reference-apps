#!/usr/bin/env node
/**
 * Headless web embedded smoke harness.
 * Uses public BundleEmbedder + NodeFsBundleLoader (no traverse-cli serve).
 *
 * Requires runtime-owned pipeline output (validate/process/summarize).
 * Exit 0 on pass. Exit 1 on failure.
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

function fail(msg) {
  console.error(`FAIL: ${msg}`)
  globalThis.process.exit(1)
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
if (invoked.length < 3) {
  fail(
    `expected ≥3 capability_invoked steps for pipeline, got ${invoked.length}. events=${JSON.stringify(events)}`,
  )
}
console.log(
  `OK: web workflow invoked — session=${outcome.sessionId} steps=${invoked.length}`,
)

const resultEvent = events.find((e) => e.event_type === 'capability_result')
if (!resultEvent) {
  fail(`missing capability_result. events=${JSON.stringify(events)}`)
}

const data = resultEvent.data && typeof resultEvent.data === 'object' ? resultEvent.data : null
const output = data?.output ?? data
if (!output || typeof output !== 'object' || Array.isArray(output)) {
  fail(`capability_result missing object output: ${JSON.stringify(resultEvent)}`)
}

const validate = output.validate
const processOut = output.process
const summarize = output.summarize
if (!validate || typeof validate.valid !== 'boolean' || !Array.isArray(validate.issues)) {
  fail(`missing runtime-owned validate fields: ${JSON.stringify(output)}`)
}
if (
  !processOut ||
  typeof processOut.title !== 'string' ||
  !processOut.title ||
  !Array.isArray(processOut.tags) ||
  typeof processOut.noteType !== 'string' ||
  typeof processOut.suggestedNextAction !== 'string' ||
  typeof processOut.status !== 'string'
) {
  fail(`missing runtime-owned process fields: ${JSON.stringify(output)}`)
}
if (
  !summarize ||
  typeof summarize.summary !== 'string' ||
  !summarize.summary ||
  typeof summarize.wordCount !== 'number'
) {
  fail(`missing runtime-owned summarize fields: ${JSON.stringify(output)}`)
}

console.log(
  `OK: web pipeline runtime-owned output — title=${JSON.stringify(processOut.title)} summary=${JSON.stringify(summarize.summary)}`,
)

embedder.shutdown()
console.log('PASS: web embedded smoke')
