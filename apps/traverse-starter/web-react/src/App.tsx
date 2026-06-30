import { useState, useEffect, useMemo } from 'react'
import { createTraverseClient } from './client/traverseClient'
import { useExecution } from './hooks/useExecution'

const baseUrl =
  import.meta.env.VITE_TRAVERSE_BASE_URL ??
  import.meta.env.VITE_TRAVERSE_RUNTIME_URL ??
  'http://127.0.0.1:8787'
const workspaceId = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'
const capabilityId = import.meta.env.VITE_TRAVERSE_CAPABILITY_ID ?? 'traverse-starter'

function App() {
  const client = useMemo(() => createTraverseClient(baseUrl), [])
  const { state: executionState, run } = useExecution(client, workspaceId)
  const [note, setNote] = useState('')
  const [status, setStatus] = useState<'checking' | 'online' | 'offline'>('checking')

  useEffect(() => {
    let active = true
    const checkHealth = async () => {
      try {
        const res = await fetch(`${baseUrl}/healthz`, { method: 'GET' })
        if (res.ok && active) {
          setStatus('online')
        } else if (active) {
          setStatus('offline')
        }
      } catch {
        if (active) {
          setStatus('offline')
        }
      }
    }

    checkHealth()
    const interval = setInterval(checkHealth, 5000)

    return () => {
      active = false
      clearInterval(interval)
    }
  }, [])

  const handleStartWorkflow = (e: React.FormEvent) => {
    e.preventDefault()
    run(capabilityId, { text: note })
  }

  const isExecuting = executionState.phase === 'loading' || executionState.phase === 'polling'

  return (
    <div style={{ maxWidth: '800px', margin: '40px auto', padding: '0 20px' }}>
      <header style={{ marginBottom: '40px', textAlign: 'center' }}>
        <h1 style={{
          fontSize: '2.5rem',
          fontWeight: 700,
          letterSpacing: '-0.03em',
          background: 'linear-gradient(to right, #a78bfa, #06b6d4)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          marginBottom: '8px',
        }}>
          Traverse Starter
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '1.05rem' }}>
          Reference UI client for Traverse runtime integration
        </p>
      </header>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <section className="glass-panel" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Runtime Environment
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Discovery Endpoint
              </div>
              <div style={{ fontSize: '1rem', color: 'var(--text-primary)', marginTop: '4px', wordBreak: 'break-all' }}>
                {baseUrl}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Runtime Status
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                <span style={{
                  display: 'inline-block',
                  width: '10px',
                  height: '10px',
                  borderRadius: '50%',
                  backgroundColor: status === 'online' ? '#06b6d4' : status === 'offline' ? '#ef4444' : '#64748b',
                  boxShadow: status === 'online' ? '0 0 10px rgba(6, 182, 212, 0.6)' : status === 'offline' ? '0 0 10px rgba(239, 68, 68, 0.6)' : 'none',
                }} />
                <span style={{ fontSize: '1rem', color: 'var(--text-primary)', fontWeight: 500 }}>
                  {status === 'online' ? 'Online' : status === 'offline' ? 'Offline' : 'Checking...'}
                </span>
              </div>
            </div>
          </div>
          <div style={{
            marginTop: '20px',
            paddingTop: '16px',
            borderTop: '1px solid rgba(255,255,255,0.05)',
            fontSize: '0.85rem',
            color: 'var(--text-muted)',
          }}>
            Workspace: <code>{workspaceId}</code> · Capability: <code>{capabilityId}</code>.
            For active local framework testing, override using <code>TRAVERSE_REPO=/path/to/Traverse</code>.
          </div>
        </section>

        <section className="glass-panel" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Start Workflow
          </h2>
          <form onSubmit={handleStartWorkflow}>
            <div style={{ marginBottom: '20px' }}>
              <label
                htmlFor="note-input"
                style={{
                  display: 'block',
                  fontSize: '0.85rem',
                  color: 'var(--text-muted)',
                  marginBottom: '8px',
                  fontWeight: 500,
                }}
              >
                Starter Input Note
              </label>
              <textarea
                id="note-input"
                value={note}
                onChange={(e) => setNote(e.target.value)}
                placeholder="Enter a note or starter input to trigger the Traverse workflow..."
                style={{
                  width: '100%',
                  minHeight: '100px',
                  padding: '12px',
                  backgroundColor: 'rgba(0, 0, 0, 0.3)',
                  border: '1px solid var(--border-glow)',
                  borderRadius: '6px',
                  color: 'var(--text-primary)',
                  fontFamily: 'var(--font-sans)',
                  fontSize: '0.95rem',
                  resize: 'vertical',
                  outline: 'none',
                  transition: 'var(--transition-smooth)',
                }}
                onFocus={(e) => { e.target.style.borderColor = 'var(--color-accent)' }}
                onBlur={(e) => { e.target.style.borderColor = 'var(--border-glow)' }}
              />
            </div>
            <button
              type="submit"
              className="btn-glow"
              disabled={!note.trim() || status !== 'online' || isExecuting}
              style={{ width: '100%' }}
            >
              {isExecuting ? 'Running...' : 'Start Workflow'}
            </button>
          </form>
        </section>

        <section className="glass-panel" style={{ padding: '24px', minHeight: '180px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Event Subscription & Result Flow
          </h2>

          {executionState.phase === 'idle' && (
            <p style={{ color: 'var(--text-muted)', fontSize: '0.95rem' }}>
              Submit a note to start a workflow. Runtime events and output will appear here.
            </p>
          )}

          {executionState.phase === 'loading' && (
            <p role="status" style={{ color: 'var(--text-secondary)' }}>Starting workflow...</p>
          )}

          {executionState.phase === 'polling' && (
            <p role="status" style={{ color: 'var(--text-secondary)' }}>
              Polling execution <code>{executionState.executionId}</code>...
            </p>
          )}

          {executionState.phase === 'failed' && (
            <p role="alert" style={{ color: '#ef4444' }}>{executionState.error}</p>
          )}

          {executionState.phase === 'succeeded' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <p role="status" style={{ color: '#06b6d4', fontWeight: 600 }}>Execution succeeded</p>
              <pre style={{
                background: 'rgba(0,0,0,0.3)',
                padding: '12px',
                borderRadius: '6px',
                overflow: 'auto',
                fontSize: '0.85rem',
              }}>
                {JSON.stringify(executionState.result.output, null, 2)}
              </pre>
              {executionState.trace.length > 0 && (
                <div>
                  <h3 style={{ fontSize: '1rem', marginBottom: '8px' }}>Trace Events</h3>
                  <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                    {executionState.trace.map((event, index) => (
                      <li key={`${event.timestamp}-${index}`} style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '4px' }}>
                        <code>{event.event_type}</code> · {event.timestamp}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}
        </section>
      </div>
    </div>
  )
}

export default App
