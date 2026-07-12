/** Process step fields (still used when process is nested under pipeline output). */
export interface ProcessOutput {
  title: string
  tags: string[]
  noteType: string
  suggestedNextAction: string
  status: string
}

export interface ValidateOutput {
  valid: boolean
  issues: string[]
}

export interface SummarizeOutput {
  summary: string
  wordCount: number
}

/** Combined pipeline final output (validate → process → summarize). */
export interface TraverseStarterOutput {
  validate: ValidateOutput
  process: ProcessOutput
  summarize: SummarizeOutput
}

function parseProcess(raw: unknown): ProcessOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  if (
    typeof o.title !== 'string' ||
    !Array.isArray(o.tags) ||
    typeof o.noteType !== 'string' ||
    typeof o.suggestedNextAction !== 'string' ||
    typeof o.status !== 'string'
  ) {
    return null
  }
  return {
    title: o.title,
    tags: o.tags as string[],
    noteType: o.noteType,
    suggestedNextAction: o.suggestedNextAction,
    status: o.status,
  }
}

function parseValidate(raw: unknown): ValidateOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  if (typeof o.valid !== 'boolean' || !Array.isArray(o.issues)) return null
  if (!o.issues.every((i) => typeof i === 'string')) return null
  return { valid: o.valid, issues: o.issues as string[] }
}

function parseSummarize(raw: unknown): SummarizeOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  if (typeof o.summary !== 'string') return null
  const wordCount =
    typeof o.wordCount === 'number'
      ? o.wordCount
      : typeof o.wordCount === 'string'
        ? Number(o.wordCount)
        : NaN
  if (!Number.isFinite(wordCount)) return null
  return { summary: o.summary, wordCount }
}

/**
 * Parses pipeline namespaced final output (validate → process → summarize).
 */
export function parseOutput(raw: unknown): TraverseStarterOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>

  const validate = parseValidate(o.validate)
  const process = parseProcess(o.process)
  const summarize = parseSummarize(o.summarize)

  if (!validate || !process || !summarize) return null
  return { validate, process, summarize }
}
