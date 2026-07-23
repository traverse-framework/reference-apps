import type {
  EmbeddedTraceApi,
  EmbeddedTraceApiError,
  EmbeddedTraceDetail,
  EmbeddedTracePage,
  EmbeddedTraceSummary,
} from 'traverse-embedder-web'

export const EMBEDDED_TRACE_API_VERSION = '1.0.0'

export type { EmbeddedTraceDetail, EmbeddedTraceSummary }

function isTraceError(
  value: EmbeddedTracePage | EmbeddedTraceDetail | EmbeddedTraceApiError,
): value is EmbeddedTraceApiError {
  return typeof value === 'object' && value !== null && 'code' in value && 'message' in value
}

/** Thin UI adapter over the public embedded-trace-api companion surface. */
export function createEmbeddedTraceClient(api: EmbeddedTraceApi) {
  return {
    apiVersion(): string {
      return api.embeddedTraceApiVersion()
    },

    list(pageSize = 20, cursor: string | null = null): EmbeddedTracePage {
      const page = api.traceList(EMBEDDED_TRACE_API_VERSION, pageSize, cursor)
      if (isTraceError(page)) {
        throw new Error(`${page.code}: ${page.message}`)
      }
      return page
    },

    get(traceId: string): EmbeddedTraceDetail {
      const detail = api.traceGet(EMBEDDED_TRACE_API_VERSION, traceId)
      if (isTraceError(detail)) {
        throw new Error(`${detail.code}: ${detail.message}`)
      }
      return detail
    },
  }
}

export function summaryPreview(summary: EmbeddedTraceSummary): string {
  return `${summary.outcome} · ${summary.targetId} · ${summary.completedAt}`
}
