/** Analyze step fields (nested under pipeline `analysis`). */
export interface AnalysisOutput {
  docType: string
  parties: string[]
  amounts: string[]
  confidence: string
  recommendation: string
}

/** Recommend step fields (nested under pipeline `recommendation`). */
export interface RecommendationOutput {
  recommendation: string
  rationale: string
  confidence: string
}

/** Combined pipeline final output (analyze → recommend). */
export interface DocApprovalOutput {
  analysis: AnalysisOutput
  recommendation: RecommendationOutput
}

function stringish(value: unknown): string | null {
  if (typeof value === 'string') return value
  if (typeof value === 'number' && Number.isFinite(value)) return String(value)
  return null
}

function parseAnalysis(raw: unknown): AnalysisOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  const confidence = stringish(o.confidence)
  if (
    typeof o.docType !== 'string' ||
    !Array.isArray(o.parties) ||
    !Array.isArray(o.amounts) ||
    confidence === null ||
    typeof o.recommendation !== 'string'
  ) {
    return null
  }
  if (!o.parties.every((p) => typeof p === 'string')) return null
  if (!o.amounts.every((a) => typeof a === 'string')) return null
  return {
    docType: o.docType,
    parties: o.parties as string[],
    amounts: o.amounts as string[],
    confidence,
    recommendation: o.recommendation,
  }
}

function parseRecommendation(raw: unknown): RecommendationOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  const confidence = stringish(o.confidence)
  if (
    typeof o.recommendation !== 'string' ||
    typeof o.rationale !== 'string' ||
    confidence === null
  ) {
    return null
  }
  return {
    recommendation: o.recommendation,
    rationale: o.rationale,
    confidence,
  }
}

/**
 * Parses pipeline namespaced final output (analyze → recommend).
 */
export function parseAnalysisOutput(raw: unknown): DocApprovalOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  const analysis = parseAnalysis(o.analysis)
  const recommendation = parseRecommendation(o.recommendation)
  if (!analysis || !recommendation) return null
  return { analysis, recommendation }
}
