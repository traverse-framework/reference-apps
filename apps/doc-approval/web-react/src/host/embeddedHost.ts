import type { JsonValue, TraverseEmbedderApi } from 'traverse-embedder-web'
import { BundleEmbedder, EmbedderTestDouble, FetchBundleLoader } from 'traverse-embedder-web'
import { parseAnalysisOutput, type DocApprovalOutput } from '../client/traverseOutput'

export const RUNTIME_MODE_EMBEDDED = 'Embedded'
export const DEFAULT_WORKFLOW_ID = 'doc-approval.pipeline'
export const DEFAULT_WORKSPACE = 'local-default'
export const DEFAULT_APP_ID = 'doc-approval'
export const DEFAULT_MANIFEST_PATH = '/bundles/doc-approval/app.manifest.json'

export type RuntimeStatus = 'starting' | 'ready' | 'unavailable'

export interface TraceEvent {
  event_type: string
  timestamp: string
  data?: unknown
}

export interface HostRunResult {
  sessionId: string
  output: DocApprovalOutput | null
  rawOutput: unknown
  events: TraceEvent[]
  error: string | null
}

export type { TraverseEmbedderApi }

export function createTestEmbedder(output: DocApprovalOutput): TraverseEmbedderApi {
  return new EmbedderTestDouble({
    workspaceId: DEFAULT_WORKSPACE,
    appId: DEFAULT_APP_ID,
    appVersion: '1.0.0',
    platform: 'web',
  }).withTargetOutput(DEFAULT_WORKFLOW_ID, output as unknown as JsonValue)
}

/** BundleEmbedder.init; returns null when the local bundle cannot be loaded. */
export async function initProductionEmbedder(
  manifestPath = import.meta.env.VITE_DOC_APPROVAL_MANIFEST ?? DEFAULT_MANIFEST_PATH,
): Promise<TraverseEmbedderApi | null> {
  try {
    return await BundleEmbedder.init({
      manifestPath,
      loader: new FetchBundleLoader(),
      workspaceId: DEFAULT_WORKSPACE,
      platform: 'web',
    })
  } catch {
    return null
  }
}

function errorMessageFromData(data: JsonValue): string | null {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return null
  const err = (data as Record<string, JsonValue>).error
  if (typeof err === 'string') return err
  if (err && typeof err === 'object' && !Array.isArray(err)) {
    const message = (err as Record<string, JsonValue>).message
    if (typeof message === 'string') return message
  }
  return null
}

export function submitDocument(embedder: TraverseEmbedderApi, document: string): HostRunResult {
  const collected: import('traverse-embedder-web').EmbedderEvent[] = []
  embedder.subscribe((event) => {
    collected.push(event)
  })

  const outcome = embedder.submit(DEFAULT_WORKFLOW_ID, { document })
  if (outcome.status === 'rejected') {
    return {
      sessionId: outcome.sessionId ?? 'sess-unknown',
      output: null,
      rawOutput: null,
      events: [],
      error: outcome.error
        ? `${outcome.error.code}: ${outcome.error.message}`
        : 'submit rejected',
    }
  }

  const sessionId = outcome.sessionId ?? 'sess-unknown'
  const events: TraceEvent[] = collected.map((event) => ({
    event_type: event.event_type,
    timestamp: String(event.sequence),
    data: event.data,
  }))

  for (const event of collected) {
    if (event.session_id && event.session_id !== sessionId) continue
    if (event.event_type === 'error') {
      return {
        sessionId,
        output: null,
        rawOutput: null,
        events,
        error: errorMessageFromData(event.data) ?? 'execution failed',
      }
    }
    if (event.event_type === 'capability_result') {
      const data =
        event.data && typeof event.data === 'object' && !Array.isArray(event.data)
          ? (event.data as Record<string, JsonValue>)
          : null
      const rawOutput = data?.output ?? null
      return {
        sessionId,
        output: parseAnalysisOutput(rawOutput),
        rawOutput,
        events,
        error: null,
      }
    }
  }

  return {
    sessionId,
    output: null,
    rawOutput: null,
    events,
    error: 'embedder emitted no capability_result',
  }
}
