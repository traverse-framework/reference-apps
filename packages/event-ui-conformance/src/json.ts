import type { JsonValue } from './types.ts'

export function isRecord(value: JsonValue): value is { [key: string]: JsonValue } {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

export function asString(value: JsonValue | undefined): string | null {
  return typeof value === 'string' ? value : null
}
