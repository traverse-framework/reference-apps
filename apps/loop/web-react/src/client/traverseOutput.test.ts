import { parseLoopOutput } from './traverseOutput'

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

describe('parseLoopOutput', () => {
  it('returns structured output for valid shape', () => {
    expect(parseLoopOutput(valid)).toEqual(valid)
  })

  it('returns null for null input', () => {
    expect(parseLoopOutput(null)).toBeNull()
  })

  it('returns null when summary is missing', () => {
    expect(parseLoopOutput({ ...valid, summary: undefined })).toBeNull()
  })

  it('returns null when action_items is not an array', () => {
    expect(parseLoopOutput({ ...valid, action_items: 'none' })).toBeNull()
  })

  it('returns null when an action item has invalid shape', () => {
    expect(parseLoopOutput({
      ...valid,
      action_items: [{ task: 'x', owner: 1, due: null }],
    })).toBeNull()
  })

  it('returns null when a decision has invalid shape', () => {
    expect(parseLoopOutput({
      ...valid,
      decisions: [{ text: 'x', made_by: 42 }],
    })).toBeNull()
  })

  it('returns null when follow_ups contains non-strings', () => {
    expect(parseLoopOutput({ ...valid, follow_ups: [1] })).toBeNull()
  })

  it('accepts empty arrays', () => {
    expect(parseLoopOutput({
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
    expect(parseLoopOutput('string')).toBeNull()
    expect(parseLoopOutput(42)).toBeNull()
  })
})
