import { useState, useEffect, useMemo, useCallback } from 'react'
import { createTraceClient, eventPreview, type TraceEvent } from './client/traceClient'
import { readUrlParams } from './urlParams'

const DEFAULT_BASE =
  import.meta.env.VITE_TRAVERSE_BASE_URL ??
  import.meta.env.VITE_TRAVERSE_RUNTIME_URL ??
  'http://127.0.0.1:8787'
const DEFAULT_WORKSPACE = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'

function App() {
  const initialParams = useMemo(() => readUrlParams(window.location.search), [])
  const baseUrl = initialParams.runtime ?? DEFAULT_BASE
  const workspace = initialParams.workspace ?? DEFAULT_WORKSPACE
  const [executionId, setExecutionId] = useState(initialParams.executionId)
  const [events, setEvents] = useState<TraceEvent[]>([])
  const [selected, setSelected] = useState<TraceEvent | null>(null)
  const [runtimeStatus, setRuntimeStatus] = useState<'checking' | 'online' | 'offline'>('checking')
  const [loadState, setLoadState] = useState<'idle' | 'loading' | 'error'>('idle')
  const [error, setError] = useState('')

  const client = useMemo(() => createTraceClient(baseUrl), [baseUrl])

  useEffect(() => {
    let active = true
    const check = async () => {
      try {
        const res = await fetch(`${baseUrl}/healthz`)
        if (active) setRuntimeStatus(res.ok ? 'online' : 'offline')
      } catch {
        if (active) setRuntimeStatus('offline')
      }
    }
    check()
    const interval = setInterval(check, 5000)
    return () => { active = false; clearInterval(interval) }
  }, [baseUrl])

  const loadTrace = useCallback(async (id: string) => {
    if (!id.trim()) return
    setLoadState('loading')
    setError('')
    setSelected(null)
    try {
      const trace = await client.fetchTrace(workspace, id.trim())
      setEvents(trace)
      setLoadState('idle')
    } catch (e) {
      setEvents([])
      setLoadState('error')
      setError(String(e))
    }
  }, [client, workspace])

  useEffect(() => {
    if (!initialParams.executionId) return
    const id = initialParams.executionId
    const timer = window.setTimeout(() => {
      void loadTrace(id)
    }, 0)
    return () => window.clearTimeout(timer)
  }, [initialParams.executionId, loadTrace])

  const handleLoad = (e: React.FormEvent) => {
    e.preventDefault()
    loadTrace(executionId)
  }

  return (
    <div style={{ maxWidth: '960px', margin: '40px auto', padding: '0 20px' }}>
      <header style={{ marginBottom: '32px', textAlign: 'center' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 700 }}>Trace Explorer</h1>
        <p style={{ color: 'var(--text-secondary)' }}>Inspect Traverse execution traces by ID</p>
      </header>

      <section className="glass-panel" style={{ padding: '24px', marginBottom: '24px' }}>
        <h2 style={{ fontSize: '1.1rem', marginBottom: '12px' }}>Runtime Environment</h2>
        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', alignItems: 'center' }}>
          <span className={runtimeStatus === 'checking' ? 'status-dot-checking' : undefined} style={{
            width: 10, height: 10, borderRadius: '50%', display: 'inline-block',
            backgroundColor: runtimeStatus === 'online' ? '#06b6d4' : runtimeStatus === 'offline' ? '#ef4444' : '#64748b',
          }} />
          <span>{runtimeStatus === 'online' ? 'Online' : runtimeStatus === 'offline' ? 'Offline' : 'Checking...'}</span>
          <span className="runtime-url">{baseUrl}</span>
          <span style={{ color: 'var(--text-muted)' }}>workspace: {workspace}</span>
        </div>
      </section>

      <section className="glass-panel" style={{ padding: '24px', marginBottom: '24px' }}>
        <form onSubmit={handleLoad}>
          <label htmlFor="exec-id" style={{ display: 'block', marginBottom: '8px', color: 'var(--text-muted)' }}>
            Execution ID
          </label>
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <input
              id="exec-id"
              value={executionId}
              onChange={(e) => setExecutionId(e.target.value)}
              placeholder="exec_abc123"
              style={{
                flex: 1, minWidth: '200px', padding: '10px', borderRadius: '6px',
                border: '1px solid var(--border-glow)', background: 'rgba(0,0,0,0.3)', color: 'var(--text-primary)',
              }}
            />
            <button type="submit" className="btn-glow" disabled={!executionId.trim() || runtimeStatus !== 'online' || loadState === 'loading'}>
              {loadState === 'loading' ? 'Loading…' : 'Load Trace'}
            </button>
          </div>
        </form>
        {runtimeStatus === 'offline' && (
          <p style={{ marginTop: '12px', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
            Runtime offline — start with <code>cargo run -p traverse-cli -- serve</code>
          </p>
        )}
      </section>

      <section className="glass-panel" style={{ padding: '24px', minHeight: '200px' }}>
        <h2 style={{ fontSize: '1.1rem', marginBottom: '16px' }}>Timeline</h2>

        {loadState === 'error' && (
          <p role="alert" style={{ color: '#ef4444' }}>{error}</p>
        )}

        {loadState !== 'loading' && events.length === 0 && loadState !== 'error' && (
          <p style={{ color: 'var(--text-muted)', textAlign: 'center' }}>
            Paste an execution ID above to load its trace.
          </p>
        )}

        {events.length > 0 && (
          <div style={{ display: 'grid', gridTemplateColumns: selected ? '1fr 1fr' : '1fr', gap: '16px' }}>
            <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
              {events.map((event, index) => (
                <li key={`${event.timestamp}-${index}`}>
                  <button
                    type="button"
                    onClick={() => setSelected(event)}
                    style={{
                      width: '100%', textAlign: 'left', padding: '10px', marginBottom: '8px',
                      background: selected === event ? 'rgba(139,92,246,0.2)' : 'rgba(0,0,0,0.25)',
                      border: '1px solid var(--border-glow)', borderRadius: '6px', color: 'var(--text-primary)', cursor: 'pointer',
                      fontFamily: 'var(--font-sans)', fontSize: '0.85rem',
                    }}
                  >
                    <div><code>{event.timestamp}</code> · <strong>{event.event_type}</strong></div>
                    <div style={{ color: 'var(--text-muted)', marginTop: '4px' }}>{eventPreview(event.data)}</div>
                  </button>
                </li>
              ))}
            </ul>
            {selected && (
              <div style={{ background: 'rgba(0,0,0,0.3)', padding: '12px', borderRadius: '6px' }}>
                <h3 style={{ fontSize: '0.9rem', marginBottom: '8px' }}>{selected.event_type}</h3>
                <pre style={{ fontSize: '0.8rem', overflow: 'auto', color: 'var(--text-secondary)' }}>
                  {JSON.stringify(selected.data ?? null, null, 2)}
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
