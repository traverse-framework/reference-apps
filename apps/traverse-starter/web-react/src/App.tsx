import { useState, useEffect, useMemo, useRef, useCallback } from 'react'
import { createTraverseClient, type TraceEvent } from './client/traverseClient'
import { useAppState } from './hooks/useAppState'
import { parseOutput } from './client/traverseOutput'

const BASE_URL =
  import.meta.env.VITE_TRAVERSE_BASE_URL ??
  import.meta.env.VITE_TRAVERSE_RUNTIME_URL ??
  'http://127.0.0.1:8787'
const WORKSPACE = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'
const APP_ID = import.meta.env.VITE_TRAVERSE_APP_ID ?? 'traverse-starter'
const NOTE_MAX_LENGTH = 2000

function App() {
  const [note, setNote] = useState('')
  const [runtimeStatus, setRuntimeStatus] = useState<'checking' | 'online' | 'offline'>('checking')
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [trace, setTrace] = useState<TraceEvent[]>([])
  const formRef = useRef<HTMLFormElement>(null)

  const client = useMemo(() => createTraverseClient(BASE_URL), [])
  const { state, output, error, executionId } = useAppState(client, WORKSPACE, APP_ID)

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

  useEffect(() => {
    if (state !== 'results' || !executionId) {
      return
    }
    let active = true
    client.fetchTrace(WORKSPACE, executionId).then(
      (events) => { if (active) setTrace(events) },
      () => { if (active) setTrace([]) },
    )
    return () => { active = false }
  }, [client, state, executionId])

  const isRunning = state === 'processing' || submitting
  const canSubmit = note.trim().length > 0 && runtimeStatus === 'online' && !isRunning

  const handleStartWorkflow = useCallback(async (e?: React.FormEvent) => {
    e?.preventDefault()
    if (!canSubmit) return
    setSubmitting(true)
    setSubmitError(null)
    setTrace([])
    try {
      // Omit session_id so each submit starts a new runtime session at initial_state.
      await client.sendCommand(WORKSPACE, APP_ID, 'submit', { note })
    } catch (err) {
      setSubmitError(String(err))
    } finally {
      setSubmitting(false)
    }
  }, [canSubmit, client, note])

  const handleNoteKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault()
      void handleStartWorkflow()
    }
  }

  const handleNoteChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setNote(e.target.value.slice(0, NOTE_MAX_LENGTH))
  }

  const displayError = submitError ?? (state === 'error' ? error : null)
  const parsed = state === 'results' ? parseOutput(output) : null

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
                Runtime URL
              </div>
              <div className="runtime-url" style={{ color: 'var(--text-primary)', marginTop: '4px' }}>
                {BASE_URL}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Runtime Status
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                <span
                  className={runtimeStatus === 'checking' ? 'status-dot-checking' : undefined}
                  style={{
                    display: 'inline-block',
                    width: '10px',
                    height: '10px',
                    borderRadius: '50%',
                    backgroundColor: runtimeStatus === 'online' ? '#06b6d4' : runtimeStatus === 'offline' ? '#ef4444' : '#64748b',
                  }}
                />
                <span style={{ fontSize: '1rem', color: 'var(--text-primary)', fontWeight: 500 }}>
                  {runtimeStatus === 'online' ? 'Online' : runtimeStatus === 'offline' ? 'Offline' : 'Checking...'}
                </span>
              </div>
            </div>
          </div>
          <div style={{ marginTop: '20px', paddingTop: '16px', borderTop: '1px solid rgba(255,255,255,0.05)', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Workspace: <strong>{WORKSPACE}</strong> · App: <strong>{APP_ID}</strong>
          </div>
        </section>

        <section className="glass-panel" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Start Workflow
          </h2>
          <form ref={formRef} onSubmit={(e) => { void handleStartWorkflow(e) }}>
            <div style={{ marginBottom: '20px' }}>
              <label htmlFor="note-input" style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '8px', fontWeight: 500 }}>
                Starter Input Note
              </label>
              <textarea
                id="note-input"
                className="note-textarea"
                value={note}
                onChange={handleNoteChange}
                onKeyDown={handleNoteKeyDown}
                placeholder="Enter a note or starter input to trigger the Traverse workflow..."
                style={{
                  width: '100%',
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
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '6px', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                <span>{note.length} / {NOTE_MAX_LENGTH}</span>
                <span>⌘/Ctrl + Enter to submit</span>
              </div>
            </div>
            <button
              type="submit"
              className="btn-glow"
              disabled={!canSubmit}
              style={{ width: '100%' }}
            >
              {isRunning ? 'Running…' : 'Start Workflow'}
            </button>
            {runtimeStatus === 'offline' && (
              <p role="status" style={{ marginTop: '12px', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                The runtime is offline. Start it with{' '}
                <code>cargo run -p traverse-cli -- serve</code> before submitting a workflow.
              </p>
            )}
          </form>
        </section>

        <section className="glass-panel" style={{ padding: '24px', minHeight: '180px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Execution Output
          </h2>

          {runtimeStatus === 'offline' && state === 'idle' && !displayError && (
            <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem', textAlign: 'center', paddingTop: '32px' }}>
              Connect to the Traverse runtime to see workflow output here.
            </div>
          )}

          {runtimeStatus !== 'offline' && state === 'idle' && !displayError && !submitting && (
            <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem', textAlign: 'center', paddingTop: '32px' }}>
              Submit a note above to start a workflow.
            </div>
          )}

          {(state === 'processing' || submitting) && !displayError && (
            <div style={{ color: 'var(--text-secondary)' }}>
              {state === 'processing' ? 'Processing…' : 'Submitting command…'}
            </div>
          )}

          {displayError && (
            <div style={{ color: '#ef4444' }}>
              <strong>Error:</strong> {displayError}
            </div>
          )}

          {state === 'results' && parsed && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <OutputField label="Valid" value={parsed.validate.valid ? 'yes' : 'no'} />
              <OutputField
                label="Issues"
                value={parsed.validate.issues.length ? parsed.validate.issues.join(', ') : 'None'}
              />
              <OutputField label="Title" value={parsed.process.title} />
              <OutputField label="Note Type" value={parsed.process.noteType} />
              <OutputField label="Status" value={parsed.process.status} />
              <OutputField label="Suggested Next Action" value={parsed.process.suggestedNextAction} />
              <div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '6px' }}>Tags</div>
                <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                  {parsed.process.tags.map(tag => (
                    <span key={tag} style={{ padding: '2px 10px', background: 'rgba(139,92,246,0.15)', color: 'var(--color-accent)', borderRadius: '20px', fontSize: '0.85rem' }}>
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
              <OutputField label="Summary" value={parsed.summarize.summary} />
              <OutputField label="Word count" value={String(parsed.summarize.wordCount)} />
              {trace.length > 0 && (
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>
                    Trace Events ({trace.length})
                  </div>
                  <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {trace.map((event, index) => (
                      <li key={`${event.timestamp}-${index}`} style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', background: 'rgba(0,0,0,0.25)', padding: '8px 12px', borderRadius: '6px' }}>
                        <div><strong>{event.event_type}</strong> · {event.timestamp}</div>
                        {event.data !== undefined && (
                          <pre style={{ marginTop: '6px', fontSize: '0.8rem', color: 'var(--text-muted)', overflow: 'auto' }}>
                            {JSON.stringify(event.data, null, 2)}
                          </pre>
                        )}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}

          {state === 'results' && !parsed && output != null && (
            <pre style={{ background: 'rgba(0,0,0,0.4)', padding: '16px', borderRadius: '6px', fontSize: '0.85rem', color: 'var(--text-primary)', overflow: 'auto' }}>
              {JSON.stringify(output, null, 2)}
            </pre>
          )}
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
