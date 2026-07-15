import { describe, it, expect } from 'vitest'
import { parseAnalysisOutput } from './traverseOutput'

const valid = {
  analysis: {
    docType: 'invoice',
    parties: ['Acme', 'Beta'],
    amounts: ['$1,200'],
    confidence: '0.92',
    recommendation: 'approve',
  },
  recommendation: {
    recommendation: 'approve',
    rationale: 'Amounts within policy',
    confidence: 'high',
  },
}

describe('parseAnalysisOutput', () => {
  it('parses pipeline namespaced output', () => {
    const result = parseAnalysisOutput(valid)
    expect(result).toEqual(valid)
  })

  it('coerces numeric confidence to string', () => {
    expect(
      parseAnalysisOutput({
        ...valid,
        analysis: { ...valid.analysis, confidence: 0.92 },
        recommendation: { ...valid.recommendation, confidence: 0.8 },
      }),
    ).toEqual({
      ...valid,
      analysis: { ...valid.analysis, confidence: '0.92' },
      recommendation: { ...valid.recommendation, confidence: '0.8' },
    })
  })

  it('returns null for missing analysis', () => {
    expect(parseAnalysisOutput({ recommendation: valid.recommendation })).toBeNull()
  })

  it('returns null for missing recommendation', () => {
    expect(parseAnalysisOutput({ analysis: valid.analysis })).toBeNull()
  })

  it('returns null for non-objects', () => {
    expect(parseAnalysisOutput(null)).toBeNull()
    expect(parseAnalysisOutput('string')).toBeNull()
    expect(parseAnalysisOutput(42)).toBeNull()
  })
})
