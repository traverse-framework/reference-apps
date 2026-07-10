import { parseMeetingNotesOutput } from './traverseOutput'

const valid = {
  action_items: [
    { task: 'Send follow-up email', owner: 'Alex', due: '2026-07-15' },
    { task: 'Update roadmap', owner: null, due: null },
  ],
  decisions: [
    { text: 'Ship Phase 1 this week', made_by: 'Jordan' },
    { text: 'Defer analytics', made_by: null },
  ],
  follow_ups: ['Schedule design review', 'Share notes with team'],
  summary: 'Team aligned on Phase 1 scope and owners.',
}

describe('parseMeetingNotesOutput', () => {
  it('returns structured output for valid shape', () => {
    expect(parseMeetingNotesOutput(valid)).toEqual(valid)
  })

  it('returns null for null input', () => {
    expect(parseMeetingNotesOutput(null)).toBeNull()
  })

  it('returns null when summary is missing', () => {
    expect(parseMeetingNotesOutput({ ...valid, summary: undefined })).toBeNull()
  })

  it('returns null when action_items is not an array', () => {
    expect(parseMeetingNotesOutput({ ...valid, action_items: 'none' })).toBeNull()
  })

  it('returns null when an action item has invalid shape', () => {
    expect(parseMeetingNotesOutput({
      ...valid,
      action_items: [{ task: 'x', owner: 1, due: null }],
    })).toBeNull()
  })

  it('returns null when a decision has invalid shape', () => {
    expect(parseMeetingNotesOutput({
      ...valid,
      decisions: [{ text: 'x', made_by: 42 }],
    })).toBeNull()
  })

  it('returns null when follow_ups contains non-strings', () => {
    expect(parseMeetingNotesOutput({ ...valid, follow_ups: [1] })).toBeNull()
  })

  it('accepts empty arrays', () => {
    expect(parseMeetingNotesOutput({
      action_items: [],
      decisions: [],
      follow_ups: [],
      summary: 'Quiet meeting.',
    })).toEqual({
      action_items: [],
      decisions: [],
      follow_ups: [],
      summary: 'Quiet meeting.',
    })
  })

  it('returns null for non-object input', () => {
    expect(parseMeetingNotesOutput('string')).toBeNull()
    expect(parseMeetingNotesOutput(42)).toBeNull()
  })
})
