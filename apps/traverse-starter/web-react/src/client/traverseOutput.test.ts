import { parseOutput } from './traverseOutput'

const valid = {
  title: 'My Note',
  tags: ['work', 'idea'],
  noteType: 'fleeting',
  suggestedNextAction: 'review',
  status: 'complete',
}

describe('parseOutput', () => {
  it('returns structured output for valid shape', () => {
    const result = parseOutput(valid)
    expect(result).toEqual(valid)
  })

  it('returns null for null input', () => {
    expect(parseOutput(null)).toBeNull()
  })

  it('returns null when title is missing', () => {
    expect(parseOutput({ ...valid, title: undefined })).toBeNull()
  })

  it('returns null when tags is not an array', () => {
    expect(parseOutput({ ...valid, tags: 'work' })).toBeNull()
  })

  it('returns null when noteType is missing', () => {
    expect(parseOutput({ ...valid, noteType: undefined })).toBeNull()
  })

  it('returns null for non-object input', () => {
    expect(parseOutput('string')).toBeNull()
    expect(parseOutput(42)).toBeNull()
  })
})
