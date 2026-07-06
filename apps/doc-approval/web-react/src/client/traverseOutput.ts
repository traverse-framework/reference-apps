export interface DocApprovalOutput {
  docType: string
  parties: string[]
  amounts: string[]
  confidence: number
  recommendation: string
}

export function parseAnalysisOutput(raw: unknown): DocApprovalOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  if (
    typeof o.docType !== 'string' ||
    !Array.isArray(o.parties) ||
    !Array.isArray(o.amounts) ||
    typeof o.confidence !== 'number' ||
    typeof o.recommendation !== 'string'
  ) return null
  if (!o.parties.every(p => typeof p === 'string')) return null
  if (!o.amounts.every(a => typeof a === 'string')) return null
  return {
    docType: o.docType,
    parties: o.parties as string[],
    amounts: o.amounts as string[],
    confidence: o.confidence,
    recommendation: o.recommendation,
  }
}
