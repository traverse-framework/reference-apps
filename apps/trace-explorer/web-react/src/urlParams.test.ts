import { describe, it, expect } from 'vitest'
import { readUrlParams } from './urlParams'

describe('readUrlParams', () => {
  it('parses execution_id and runtime params', () => {
    expect(readUrlParams('?execution_id=exec-1&runtime=http://127.0.0.1:8787&workspace=local-default')).toEqual({
      executionId: 'exec-1',
      runtime: 'http://127.0.0.1:8787',
      workspace: 'local-default',
    })
  })

  it('returns empty executionId when absent', () => {
    expect(readUrlParams('')).toEqual({ executionId: '', runtime: undefined, workspace: undefined })
  })
})
