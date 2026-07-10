export interface ActionItem {
  task: string
  owner: string | null
  due: string | null
}

export interface Decision {
  text: string
  made_by: string | null
}

export interface MeetingNotesOutput {
  action_items: ActionItem[]
  decisions: Decision[]
  follow_ups: string[]
  summary: string
}

function isNullableString(value: unknown): value is string | null {
  return value === null || typeof value === 'string'
}

function isActionItem(value: unknown): value is ActionItem {
  if (!value || typeof value !== 'object') return false
  const o = value as Record<string, unknown>
  return typeof o.task === 'string' && isNullableString(o.owner) && isNullableString(o.due)
}

function isDecision(value: unknown): value is Decision {
  if (!value || typeof value !== 'object') return false
  const o = value as Record<string, unknown>
  return typeof o.text === 'string' && isNullableString(o.made_by)
}

export function parseMeetingNotesOutput(raw: unknown): MeetingNotesOutput | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  if (
    !Array.isArray(o.action_items) ||
    !Array.isArray(o.decisions) ||
    !Array.isArray(o.follow_ups) ||
    typeof o.summary !== 'string'
  ) return null
  if (!o.action_items.every(isActionItem)) return null
  if (!o.decisions.every(isDecision)) return null
  if (!o.follow_ups.every(item => typeof item === 'string')) return null
  return {
    action_items: o.action_items as ActionItem[],
    decisions: o.decisions as Decision[],
    follow_ups: o.follow_ups as string[],
    summary: o.summary,
  }
}
