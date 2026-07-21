import { useState, useEffect, useCallback } from 'react'
import { HealthIndicator } from './components/HealthIndicator'
import { TranscriptInput } from './components/TranscriptInput'
import { MeetingResult } from './components/MeetingResult'
import {
  DEFAULT_WORKFLOW_ID,
  DEFAULT_WORKSPACE,
  initProductionEmbedder,
  submitTranscript,
  type HostRunResult,
  type RuntimeStatus,
  type TraverseEmbedderApi,
} from './host/embeddedHost'

const TRANSCRIPT_MAX_LENGTH = 5000

export interface AppProps {
  embedder?: TraverseEmbedderApi | null
}

function App({ embedder: injectedEmbedder }: AppProps = {}) {
  const injected = injectedEmbedder !== undefined
  const [transcript, setTranscript] = useState('')
  const [prodStatus, setProdStatus] = useState<RuntimeStatus>('starting')
  const [prodEmbedder, setProdEmbedder] = useState<TraverseEmbedderApi | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState<HostRunResult | null>(null)

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
  const canSubmit = transcript.trim().length > 0 && runtimeStatus === 'ready' && !isRunning

  const handleSubmit = useCallback(
    (e?: React.FormEvent) => {
      e?.preventDefault()
      if (!canSubmit || !embedder) return
      setSubmitting(true)
      setResult(null)
      try {
        setResult(submitTranscript(embedder, transcript))
      } finally {
        setSubmitting(false)
      }
    },
    [canSubmit, embedder, transcript],
  )

  const handleReset = useCallback(() => {
    setResult(null)
    setTranscript('')
  }, [])

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
          Meeting Notes
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '1.05rem' }}>
          Extract action items and decisions from transcripts via the Traverse runtime
        </p>
      </header>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <HealthIndicator
          workspace={DEFAULT_WORKSPACE}
          workflowId={DEFAULT_WORKFLOW_ID}
          status={runtimeStatus}
        />

        <TranscriptInput
          transcript={transcript}
          maxLength={TRANSCRIPT_MAX_LENGTH}
          canSubmit={canSubmit}
          isRunning={isRunning}
          runtimeUnavailable={runtimeStatus === 'unavailable'}
          onChange={setTranscript}
          onSubmit={handleSubmit}
        />

        <MeetingResult
          result={result}
          submitting={submitting}
          runtimeUnavailable={runtimeStatus === 'unavailable'}
          onReset={handleReset}
        />
      </div>
    </div>
  )
}

export default App
