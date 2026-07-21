import { parseOutput } from './traverseOutput'

const valid = {
  validate: { valid: true, issues: [] as string[] },
  process: {
    title: 'Meeting notes',
    tags: ['work'],
    noteType: 'meeting',
    suggestedNextAction: 'review',
    status: 'complete',
  },
  summarize: { summary: 'A short summary', wordCount: 3 },
}

describe('parseOutput', () => {
  it('parses pipeline namespaced output', () => {
    const result = parseOutput(valid)
    expect(result?.process.title).toBe('Meeting notes')
    expect(result?.summarize.wordCount).toBe(3)
    expect(result?.validate.valid).toBe(true)
  })

  it('returns null for null', () => {
    expect(parseOutput(null)).toBeNull()
  })

  it('returns null when process is missing', () => {
    expect(parseOutput({ ...valid, process: undefined })).toBeNull()
  })

  it('returns null for flat legacy process-only payloads', () => {
    expect(
      parseOutput({
        title: 'T',
        tags: [],
        noteType: 'n',
        suggestedNextAction: 'x',
        status: 'done',
      }),
    ).toBeNull()
  })

  it('returns null for non-objects', () => {
    expect(parseOutput('string')).toBeNull()
    expect(parseOutput(42)).toBeNull()
  })
})

  it('returns null when process fields have wrong types', () => {
    expect(
      parseOutput({
        ...valid,
        process: { title: 1, tags: [], noteType: 'n', suggestedNextAction: 'x', status: 's' },
      }),
    ).toBeNull()
  })

  it('returns null when validate fields are invalid', () => {
    expect(parseOutput({ ...valid, validate: { valid: 'yes', issues: [] } })).toBeNull()
    expect(parseOutput({ ...valid, validate: { valid: true, issues: [1] } })).toBeNull()
  })

  it('returns null when summarize fields are invalid', () => {
    expect(parseOutput({ ...valid, summarize: { summary: 1, wordCount: 1 } })).toBeNull()
    expect(parseOutput({ ...valid, summarize: { summary: 's', wordCount: 'x' } })).toBeNull()
  })

  it('accepts summarize.wordCount as numeric string', () => {
    const result = parseOutput({
      ...valid,
      summarize: { summary: 's', wordCount: '4' },
    })
    expect(result?.summarize.wordCount).toBe(4)
  })
