import { parseAnalysisOutput } from './traverseOutput'

const valid = {
  docType: 'invoice',
  parties: ['Acme Corp', 'Beta LLC'],
  amounts: ['$1,200.00', '$300.00'],
  confidence: 0.92,
  recommendation: 'approve',
}

describe('parseAnalysisOutput', () => {
  it('returns structured output for valid shape', () => {
    expect(parseAnalysisOutput(valid)).toEqual(valid)
  })

  it('returns null for null input', () => {
    expect(parseAnalysisOutput(null)).toBeNull()
  })

  it('returns null when docType is missing', () => {
    expect(parseAnalysisOutput({ ...valid, docType: undefined })).toBeNull()
  })

  it('returns null when parties is not an array', () => {
    expect(parseAnalysisOutput({ ...valid, parties: 'Acme' })).toBeNull()
  })

  it('returns null when confidence is not a number', () => {
    expect(parseAnalysisOutput({ ...valid, confidence: 'high' })).toBeNull()
  })

  it('returns null for non-object input', () => {
    expect(parseAnalysisOutput('string')).toBeNull()
    expect(parseAnalysisOutput(42)).toBeNull()
  })
})
