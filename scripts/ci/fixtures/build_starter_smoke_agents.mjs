#!/usr/bin/env node
/**
 * Build deterministic WASI smoke agents for traverse-starter.pipeline.
 * Each agent writes fixed contract-shaped JSON to stdout (no UI business logic).
 *
 * Usage: node scripts/ci/fixtures/build_starter_smoke_agents.mjs
 */
import initWabt from 'wabt'
import { writeFileSync, mkdirSync } from 'node:fs'
import { createHash } from 'node:crypto'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const outDir = join(here, 'traverse-starter-smoke-agents')

function watFixedJson(json) {
  const bytes = Buffer.from(json, 'utf8')
  const escaped = [...bytes].map((b) => `\\${b.toString(16).padStart(2, '0')}`).join('')
  return `
  (module
    (import "wasi_snapshot_preview1" "fd_write"
      (func $fd_write (param i32 i32 i32 i32) (result i32)))
    (memory (export "memory") 1)
    (data (i32.const 16) "${escaped}")
    (func (export "_start")
      (i32.store (i32.const 0) (i32.const 16))
      (i32.store (i32.const 4) (i32.const ${bytes.length}))
      (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 8)))
    )
  )`
}

const agents = {
  validate: '{"valid":true,"issues":[]}',
  process:
    '{"title":"Meeting notes","tags":["meeting","design"],"noteType":"meeting","suggestedNextAction":"Schedule follow-up","status":"ready"}',
  summarize: '{"summary":"Design onboarding discussion","wordCount":3}',
}

const wabt = await initWabt()
mkdirSync(outDir, { recursive: true })

const digests = {}
for (const [name, json] of Object.entries(agents)) {
  const module = wabt.parseWat(`${name}.wat`, watFixedJson(json))
  const { buffer } = module.toBinary({})
  const wasm = Buffer.from(buffer)
  const file = `${name}-agent.wasm`
  writeFileSync(join(outDir, file), wasm)
  const digest = `sha256:${createHash('sha256').update(wasm).digest('hex')}`
  digests[name] = { file, digest, bytes: wasm.length }
  console.log(`OK: ${file} ${digest} (${wasm.length} bytes)`)
}

writeFileSync(join(outDir, 'digests.json'), `${JSON.stringify(digests, null, 2)}\n`)
writeFileSync(
  join(outDir, 'README.md'),
  `# traverse-starter smoke agents

Deterministic WASI command modules used only by \`scripts/ci/embedded_smoke.sh\`.
Each writes fixed JSON matching the public capability contracts (validate / process / summarize).

Rebuild: \`node scripts/ci/fixtures/build_starter_smoke_agents.mjs\` (requires \`wabt\`).

These are **not** UI business logic — they stand in for Traverse example agents until
those ship non-stub WASM. Digests are applied to the smoke bundle at prepare time.
`,
)
console.log(`OK: wrote digests → ${join(outDir, 'digests.json')}`)
