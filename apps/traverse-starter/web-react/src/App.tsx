import { useState, useEffect, useCallback, useRef } from 'react'
import {
  DEFAULT_APP_ID,
  DEFAULT_WORKFLOW_ID,
  DEFAULT_WORKSPACE,
  RUNTIME_MODE_EMBEDDED,
  initProductionEmbedder,
  submitNote,
  type HostRunResult,
  type RuntimeStatus,
  type TraceEvent,
  type TraverseEmbedderApi,
} from './host/embeddedHost'
import { type TraverseStarterOutput } from './client/traverseOutput'

const NOTE_MAX_LENGTH = 2000

export interface AppProps {
  /** Injected embedder for tests; when omitted, production BundleEmbedder.init runs. */
  embedder?: TraverseEmbedderApi | null
}

function App({ embedder: injectedEmbedder }: AppProps = {}) {
  const injected = injectedEmbedder !== undefined
  const [note, setNote] = useState('')
  const [prodStatus, setProdStatus] = useState<RuntimeStatus>('starting')
  const [prodEmbedder, setProdEmbedder] = useState<TraverseEmbedderApi | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState<HostRunResult | null>(null)
  const formRef = useRef<HTMLFormElement>(null)

  const embedder = injected ? injectedEmbedder : prodEmbedder
  const runtimeStatus: RuntimeStatus = injected
    ? injectedEmbedder
      ? 'ready'
      : 'unavailable'
    : prodStatus

  useEffect(() => {
    if (injected) return
    let active = true
    void initProductionEmbedder().then((instance) => {
      if (!active) return
      setProdEmbedder(instance)
      setProdStatus(instance ? 'ready' : 'unavailable')
    })
    return () => {
      active = false
    }
  }, [injected])

  const isRunning = submitting
  const canSubmit = note.trim().length > 0 && runtimeStatus === 'ready' && !isRunning

  const handleStartWorkflow = useCallback(
    (e?: React.FormEvent) => {
      e?.preventDefault()
      if (!canSubmit || !embedder) return
      setSubmitting(true)
      setResult(null)
      try {
        setResult(submitNote(embedder, note))
      } finally {
        setSubmitting(false)
      }
    },
    [canSubmit, embedder, note],
  )

  const handleNoteKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault()
      handleStartWorkflow()
    }
  }

  const handleNoteChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setNote(e.target.value.slice(0, NOTE_MAX_LENGTH))
  }

  const parsed: TraverseStarterOutput | null = result?.output ?? null
  const displayError = result?.error ?? null
  const trace: TraceEvent[] = result?.events ?? []
  const statusLabel =
    runtimeStatus === 'ready' ? 'Ready' : runtimeStatus === 'unavailable' ? 'Unavailable' : 'Starting'

  return (
    <div style={{ maxWidth: '800px', margin: '40px auto', padding: '0 20px' }}>
      <header style={{ marginBottom: '40px', textAlign: 'center' }}>
        <h1
          style={{
            fontSize: '2.5rem',
            fontWeight: 700,
            letterSpacing: '-0.03em',
            background: 'linear-gradient(to right, #a78bfa, #06b6d4)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            marginBottom: '8px',
          }}
        >
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
              <div
                style={{
                  fontSize: '0.85rem',
                  color: 'var(--text-muted)',
                  textTransform: 'uppercase',
                  letterSpacing: '0.05em',
                }}
              >
                Runtime mode
              </div>
              <div style={{ color: 'var(--text-primary)', marginTop: '4px' }}>
                {RUNTIME_MODE_EMBEDDED}
              </div>
            </div>
            <div>
              <div
                style={{
                  fontSize: '0.85rem',
                  color: 'var(--text-muted)',
                  textTransform: 'uppercase',
                  letterSpacing: '0.05em',
                }}
              >
                Runtime Status
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                <span
                  className={runtimeStatus === 'starting' ? 'status-dot-checking' : undefined}
                  style={{
                    display: 'inline-block',
                    width: '10px',
                    height: '10px',
                    borderRadius: '50%',
                    backgroundColor:
                      runtimeStatus === 'ready'
                        ? '#06b6d4'
                        : runtimeStatus === 'unavailable'
                          ? '#ef4444'
                          : '#64748b',
                  }}
                />
                <span style={{ fontSize: '1rem', color: 'var(--text-primary)', fontWeight: 500 }}>
                  {statusLabel}
                </span>
              </div>
            </div>
          </div>
          <div
            style={{
              marginTop: '20px',
              paddingTop: '16px',
              borderTop: '1px solid rgba(255,255,255,0.05)',
              fontSize: '0.85rem',
              color: 'var(--text-muted)',
            }}
          >
            Workspace: <strong>{DEFAULT_WORKSPACE}</strong> · Workflow:{' '}
            <strong>{DEFAULT_WORKFLOW_ID}</strong> · App: <strong>{DEFAULT_APP_ID}</strong>
          </div>
        </section>

        <section className="glass-panel" style={{ padding: '24px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Start Workflow
          </h2>
          <form
            ref={formRef}
            onSubmit={(e) => {
              handleStartWorkflow(e)
            }}
          >
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
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  marginTop: '6px',
                  fontSize: '0.8rem',
                  color: 'var(--text-muted)',
                }}
              >
                <span>
                  {note.length} / {NOTE_MAX_LENGTH}
                </span>
                <span>⌘/Ctrl + Enter to submit</span>
              </div>
            </div>
            <button type="submit" className="btn-glow" disabled={!canSubmit} style={{ width: '100%' }}>
              {isRunning ? 'Running…' : 'Start Workflow'}
            </button>
            {runtimeStatus === 'unavailable' && (
              <p role="status" style={{ marginTop: '12px', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                Embedded runtime unavailable — sync the app bundle with{' '}
                <code>bash scripts/ci/sync_web_starter_bundle.sh</code> (requires{' '}
                <code>TRAVERSE_REPO</code>).
              </p>
            )}
          </form>
        </section>

        <section className="glass-panel" style={{ padding: '24px', minHeight: '180px' }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
            Execution Output
          </h2>

          {runtimeStatus === 'unavailable' && !displayError && !parsed && !submitting && (
            <div
              style={{
                color: 'var(--text-muted)',
                fontSize: '0.95rem',
                textAlign: 'center',
                paddingTop: '32px',
              }}
            >
              Initialize the embedded runtime to see workflow output here.
            </div>
          )}

          {runtimeStatus === 'ready' && !displayError && !parsed && !submitting && (
            <div
              style={{
                color: 'var(--text-muted)',
                fontSize: '0.95rem',
                textAlign: 'center',
                paddingTop: '32px',
              }}
            >
              Submit a note above to start a workflow.
            </div>
          )}

          {submitting && !displayError && (
            <div style={{ color: 'var(--text-secondary)' }}>Running embedded workflow…</div>
          )}

          {displayError && (
            <div style={{ color: '#ef4444' }}>
              <strong>Error:</strong> {displayError}
            </div>
          )}

          {parsed && (
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
                <div
                  style={{
                    fontSize: '0.75rem',
                    color: 'var(--text-muted)',
                    textTransform: 'uppercase',
                    letterSpacing: '0.05em',
                    marginBottom: '6px',
                  }}
                >
                  Tags
                </div>
                <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                  {parsed.process.tags.map((tag) => (
                    <span
                      key={tag}
                      style={{
                        padding: '2px 10px',
                        background: 'rgba(139,92,246,0.15)',
                        color: 'var(--color-accent)',
                        borderRadius: '20px',
                        fontSize: '0.85rem',
                      }}
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
              <OutputField label="Summary" value={parsed.summarize.summary} />
              <OutputField label="Word count" value={String(parsed.summarize.wordCount)} />
              {trace.length > 0 && (
                <div>
                  <div
                    style={{
                      fontSize: '0.75rem',
                      color: 'var(--text-muted)',
                      textTransform: 'uppercase',
                      letterSpacing: '0.05em',
                      marginBottom: '8px',
                    }}
                  >
                    Trace Events ({trace.length})
                  </div>
                  <ul
                    style={{
                      listStyle: 'none',
                      padding: 0,
                      margin: 0,
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '8px',
                    }}
                  >
                    {trace.map((event, index) => (
                      <li
                        key={`${event.timestamp}-${index}`}
                        style={{
                          fontSize: '0.85rem',
                          color: 'var(--text-secondary)',
                          background: 'rgba(0,0,0,0.25)',
                          padding: '8px 12px',
                          borderRadius: '6px',
                        }}
                      >
                        <div>
                          <strong>{event.event_type}</strong> · {event.timestamp}
                        </div>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}

          {!parsed && result?.rawOutput != null && !displayError && (
            <pre
              style={{
                background: 'rgba(0,0,0,0.4)',
                padding: '16px',
                borderRadius: '6px',
                fontSize: '0.85rem',
                color: 'var(--text-primary)',
                overflow: 'auto',
              }}
            >
              {JSON.stringify(result.rawOutput, null, 2)}
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
      <div
        style={{
          fontSize: '0.75rem',
          color: 'var(--text-muted)',
          textTransform: 'uppercase',
          letterSpacing: '0.05em',
          marginBottom: '4px',
        }}
      >
        {label}
      </div>
      <div style={{ fontSize: '1rem', color: 'var(--text-primary)' }}>{value}</div>
    </div>
  )
}

export default App
