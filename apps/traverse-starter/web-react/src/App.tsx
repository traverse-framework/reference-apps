import { useState, useEffect, useMemo } from 'react'
import { createTraverseClient } from './client/traverseClient'
import { useExecution } from './hooks/useExecution'
import { parseOutput } from './client/traverseOutput'

const BASE_URL = import.meta.env.VITE_TRAVERSE_BASE_URL ?? 'http://127.0.0.1:8787'
const WORKSPACE = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'

function App() {
  const [note, setNote] = useState('')
  const [runtimeStatus, setRuntimeStatus] = useState<'checking' | 'online' | 'offline'>('checking')

  const client = useMemo(() => createTraverseClient(BASE_URL), [])
  const { state, run } = useExecution(client, WORKSPACE)

  useEffect(() => {
    let active = true
    const check = async () => {
      try {
        const res = await fetch(`${BASE_URL}/healthz`)
        if (active) setRuntimeStatus(res.ok ? 'online' : 'offline')
      } catch {
        if (active) setRuntimeStatus('offline')
      }
    }
    check()
    const interval = setInterval(check, 5000)
    return () => { active = false; clearInterval(interval) }
  }, [])

  const handleStartWorkflow = (e: React.FormEvent) => {
    e.preventDefault()
    run('traverse-starter.process', { note })
  }

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

        {/* Runtime status */}
        <section className="glass-panel" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Runtime Environment
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Base URL
              </div>
              <div style={{ fontSize: '1rem', color: 'var(--text-primary)', marginTop: '4px', wordBreak: 'break-all' }}>
                {BASE_URL}
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
                  backgroundColor: runtimeStatus === 'online' ? '#06b6d4' : runtimeStatus === 'offline' ? '#ef4444' : '#64748b',
                }} />
                <span style={{ fontSize: '1rem', color: 'var(--text-primary)', fontWeight: 500 }}>
                  {runtimeStatus === 'online' ? 'Online' : runtimeStatus === 'offline' ? 'Offline' : 'Checking...'}
                </span>
              </div>
            </div>
          </div>
          <div style={{ marginTop: '20px', paddingTop: '16px', borderTop: '1px solid rgba(255,255,255,0.05)', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Workspace: <strong>{WORKSPACE}</strong> · Override with <code>VITE_TRAVERSE_BASE_URL</code> / <code>VITE_TRAVERSE_WORKSPACE</code>
          </div>
        </section>

        {/* Input */}
        <section className="glass-panel" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Start Workflow
          </h2>
          <form onSubmit={handleStartWorkflow}>
            <div style={{ marginBottom: '20px' }}>
              <label htmlFor="note-input" style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '8px', fontWeight: 500 }}>
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
                }}
              />
            </div>
            <button
              type="submit"
              className="btn-glow"
              disabled={!note.trim() || runtimeStatus !== 'online' || state.phase === 'loading' || state.phase === 'polling'}
              style={{ width: '100%' }}
            >
              {state.phase === 'loading' || state.phase === 'polling' ? 'Running…' : 'Start Workflow'}
            </button>
          </form>
        </section>

        {/* Execution output */}
        <section className="glass-panel" style={{ padding: '24px', minHeight: '180px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Execution Output
          </h2>

          {state.phase === 'idle' && (
            <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem', textAlign: 'center', paddingTop: '32px' }}>
              Submit a note above to start a workflow.
            </div>
          )}

          {state.phase === 'loading' && (
            <div style={{ color: 'var(--text-secondary)' }}>Starting execution…</div>
          )}

          {state.phase === 'polling' && (
            <div style={{ color: 'var(--text-secondary)' }}>
              Polling execution <code>{state.executionId}</code>…
            </div>
          )}

          {state.phase === 'failed' && (
            <div style={{ color: '#ef4444' }}>
              <strong>Error:</strong> {state.error}
            </div>
          )}

          {state.phase === 'succeeded' && (() => {
            const output = parseOutput(state.result.output)
            return output ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <OutputField label="Title" value={output.title} />
                <OutputField label="Note Type" value={output.noteType} />
                <OutputField label="Status" value={output.status} />
                <OutputField label="Suggested Next Action" value={output.suggestedNextAction} />
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '6px' }}>Tags</div>
                  <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                    {output.tags.map(tag => (
                      <span key={tag} style={{ padding: '2px 10px', background: 'rgba(139,92,246,0.15)', color: 'var(--color-accent)', borderRadius: '20px', fontSize: '0.85rem' }}>
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
                {state.trace.length > 0 && (
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                    {state.trace.length} trace event{state.trace.length !== 1 ? 's' : ''}
                  </div>
                )}
              </div>
            ) : (
              <pre style={{ background: 'rgba(0,0,0,0.4)', padding: '16px', borderRadius: '6px', fontSize: '0.85rem', color: 'var(--text-primary)', overflow: 'auto' }}>
                {JSON.stringify(state.result.output, null, 2)}
              </pre>
            )
          })()}
        </section>

      </div>
    </div>
  )
}

function OutputField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '4px' }}>{label}</div>
      <div style={{ fontSize: '1rem', color: 'var(--text-primary)' }}>{value}</div>
    </div>
  )
}

export default App
