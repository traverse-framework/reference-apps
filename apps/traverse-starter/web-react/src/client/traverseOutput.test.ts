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
