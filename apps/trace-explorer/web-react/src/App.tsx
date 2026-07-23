import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  EmbedderTestDouble,
  type EmbeddedTraceApi,
  type EmbeddedTraceDetail,
  type EmbeddedTraceSummary,
} from 'traverse-embedder-web'
import {
  createEmbeddedTraceClient,
  summaryPreview,
} from './client/traceClient'

/** Injected host for tests; production uses EmbedderTestDouble until a session host is wired. */
export type TraceHostFactory = () => EmbeddedTraceApi

const defaultHostFactory: TraceHostFactory = () => new EmbedderTestDouble()

function App({
  hostFactory = defaultHostFactory,
  host,
}: {
  hostFactory?: TraceHostFactory
  host?: EmbeddedTraceApi
}) {
  const api = useMemo(() => host ?? hostFactory(), [host, hostFactory])
  const client = useMemo(() => createEmbeddedTraceClient(api), [api])

  const [summaries, setSummaries] = useState<EmbeddedTraceSummary[]>([])
  const [selected, setSelected] = useState<EmbeddedTraceDetail | null>(null)
  const [loadState, setLoadState] = useState<'idle' | 'loading' | 'error'>('idle')
  const [error, setError] = useState('')
  const [apiVersion, setApiVersion] = useState('')

  const refreshList = useCallback(() => {
    setLoadState('loading')
    setError('')
    try {
      setApiVersion(client.apiVersion())
      const page = client.list(50)
      setSummaries([...page.summaries])
      setLoadState('idle')
    } catch (e) {
      setSummaries([])
      setLoadState('error')
      setError(String(e))
    }
  }, [client])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      refreshList()
    }, 0)
    return () => window.clearTimeout(timer)
  }, [refreshList])

  const openTrace = (traceId: string) => {
    setLoadState('loading')
    setError('')
    try {
      setSelected(client.get(traceId))
      setLoadState('idle')
    } catch (e) {
      setSelected(null)
      setLoadState('error')
      setError(String(e))
    }
  }

  return (
    <div style={{ maxWidth: '960px', margin: '40px auto', padding: '0 20px' }}>
      <header style={{ marginBottom: '32px', textAlign: 'center' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 700 }}>Trace Explorer</h1>
        <p style={{ color: 'var(--text-secondary)' }}>
          Browse local embedded execution traces (no sidecar)
        </p>
      </header>

      <section className="glass-panel" style={{ padding: '24px', marginBottom: '24px' }}>
        <h2 style={{ fontSize: '1.1rem', marginBottom: '12px' }}>Embedded Trace API</h2>
        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', alignItems: 'center' }}>
          <span
            style={{
              width: 10,
              height: 10,
              borderRadius: '50%',
              display: 'inline-block',
              backgroundColor: '#06b6d4',
            }}
          />
          <span>Embedded · {apiVersion || '…'}</span>
          <button type="button" className="btn-glow" onClick={refreshList}>
            Refresh
          </button>
        </div>
      </section>

      <section className="glass-panel" style={{ padding: '24px', minHeight: '200px' }}>
        <h2 style={{ fontSize: '1.1rem', marginBottom: '16px' }}>Traces</h2>

        {loadState === 'error' && (
          <p role="alert" style={{ color: '#ef4444' }}>{error}</p>
        )}

        {loadState !== 'loading' && summaries.length === 0 && loadState !== 'error' && (
          <p style={{ color: 'var(--text-muted)', textAlign: 'center' }}>
            No retained traces in this local session yet. Run an embedded workflow, then refresh.
          </p>
        )}

        {summaries.length > 0 && (
          <div style={{ display: 'grid', gridTemplateColumns: selected ? '1fr 1fr' : '1fr', gap: '16px' }}>
            <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
              {summaries.map((summary) => (
                <li key={summary.traceId}>
                  <button
                    type="button"
                    onClick={() => openTrace(summary.traceId)}
                    style={{
                      width: '100%',
                      textAlign: 'left',
                      padding: '10px',
                      marginBottom: '8px',
                      background:
                        selected?.summary.traceId === summary.traceId
                          ? 'rgba(139,92,246,0.2)'
                          : 'rgba(0,0,0,0.25)',
                      border: '1px solid var(--border-glow)',
                      borderRadius: '6px',
                      color: 'var(--text-primary)',
                      cursor: 'pointer',
                      fontFamily: 'var(--font-sans)',
                      fontSize: '0.85rem',
                    }}
                  >
                    <div>
                      <code>{summary.traceId}</code> · <strong>{summary.outcome}</strong>
                    </div>
                    <div style={{ color: 'var(--text-muted)', marginTop: '4px' }}>
                      {summaryPreview(summary)}
                    </div>
                  </button>
                </li>
              ))}
            </ul>
            {selected && (
              <div style={{ background: 'rgba(0,0,0,0.3)', padding: '12px', borderRadius: '6px' }}>
                <h3 style={{ fontSize: '0.9rem', marginBottom: '8px' }}>
                  {selected.summary.traceId}
                </h3>
                <pre style={{ fontSize: '0.8rem', overflow: 'auto', color: 'var(--text-secondary)' }}>
                  {JSON.stringify(selected, null, 2)}
                </pre>
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  )
}

export default App
