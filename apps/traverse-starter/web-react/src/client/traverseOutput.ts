export interface TraverseStarterOutput {
  title: string
  tags: string[]
  noteType: string
  suggestedNextAction: string
  status: string
}

export function parseOutput(raw: unknown): TraverseStarterOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  if (
    typeof o.title !== 'string' ||
    !Array.isArray(o.tags) ||
    typeof o.noteType !== 'string' ||
    typeof o.suggestedNextAction !== 'string' ||
    typeof o.status !== 'string'
  ) return null
  return {
    title: o.title,
    tags: o.tags as string[],
    noteType: o.noteType,
    suggestedNextAction: o.suggestedNextAction,
    status: o.status,
  }
}
