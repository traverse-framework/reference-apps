export interface UrlParams {
  executionId: string
  runtime?: string
  workspace?: string
}

export function readUrlParams(search: string): UrlParams {
  const params = new URLSearchParams(search)
  return {
    executionId: params.get('execution_id') ?? '',
    runtime: params.get('runtime') ?? undefined,
    workspace: params.get('workspace') ?? undefined,
  }
}
