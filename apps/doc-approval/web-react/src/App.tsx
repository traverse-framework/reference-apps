import { useState, useEffect, useCallback } from 'react'
import { HealthIndicator } from './components/HealthIndicator'
import { DocumentInput } from './components/DocumentInput'
import { AnalysisResult } from './components/AnalysisResult'
import {
  DEFAULT_WORKFLOW_ID,
  DEFAULT_WORKSPACE,
  initProductionEmbedder,
  submitDocument,
  type HostRunResult,
  type RuntimeStatus,
  type TraverseEmbedderApi,
} from './host/embeddedHost'

const DOCUMENT_MAX_LENGTH = 10000

export interface AppProps {
  embedder?: TraverseEmbedderApi | null
}

function App({ embedder: injectedEmbedder }: AppProps = {}) {
  const injected = injectedEmbedder !== undefined
  const [document, setDocument] = useState('')
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
  const canSubmit = document.trim().length > 0 && runtimeStatus === 'ready' && !isRunning

  const handleSubmit = useCallback(
    (e?: React.FormEvent) => {
      e?.preventDefault()
      if (!canSubmit || !embedder) return
      setSubmitting(true)
      setResult(null)
      try {
        setResult(submitDocument(embedder, document))
      } finally {
        setSubmitting(false)
      }
    },
    [canSubmit, embedder, document],
  )

  const handleReset = useCallback(() => {
    setResult(null)
    setDocument('')
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
          Doc Approval
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '1.05rem' }}>
          Submit documents for AI analysis via the Traverse runtime
        </p>
      </header>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <HealthIndicator
          workspace={DEFAULT_WORKSPACE}
          workflowId={DEFAULT_WORKFLOW_ID}
          status={runtimeStatus}
        />

        <DocumentInput
          document={document}
          maxLength={DOCUMENT_MAX_LENGTH}
          canSubmit={canSubmit}
          isRunning={isRunning}
          runtimeUnavailable={runtimeStatus === 'unavailable'}
          onChange={setDocument}
          onSubmit={handleSubmit}
        />

        <AnalysisResult
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
