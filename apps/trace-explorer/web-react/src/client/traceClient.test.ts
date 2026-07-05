import { describe, it, expect } from 'vitest'
import { eventPreview } from './traceClient'

describe('eventPreview', () => {
  it('returns em dash for nullish data', () => {
    expect(eventPreview(undefined)).toBe('—')
    expect(eventPreview(null)).toBe('—')
  })

  it('truncates long JSON previews', () => {
    const long = { title: 'x'.repeat(80) }
    expect(eventPreview(long).endsWith('…')).toBe(true)
  })
})
