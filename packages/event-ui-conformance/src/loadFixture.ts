import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import type { FixtureCase, FixtureCatalog } from './types.ts'

const PACKAGE_DIR = dirname(fileURLToPath(import.meta.url))
export const FIXTURES_DIR = join(PACKAGE_DIR, '../../../fixtures/event-ui-conformance')

export function loadCatalog(): FixtureCatalog {
  const raw = readFileSync(join(FIXTURES_DIR, 'catalog.json'), 'utf8')
  return JSON.parse(raw) as FixtureCatalog
}

export function loadFixtureCase(fileName: string): FixtureCase {
  const raw = readFileSync(join(FIXTURES_DIR, fileName), 'utf8')
  return JSON.parse(raw) as FixtureCase
}

export function loadAllFixtureCases(): FixtureCase[] {
  return loadCatalog().cases.map((entry) => loadFixtureCase(entry.file))
}
