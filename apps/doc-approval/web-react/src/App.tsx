import { useState, useEffect, useMemo, useCallback } from 'react'
import { createTraverseClient } from './client/traverseClient'
import { useExecution } from './hooks/useExecution'
import { HealthIndicator } from './components/HealthIndicator'
import { DocumentInput } from './components/DocumentInput'
import { AnalysisResult } from './components/AnalysisResult'

const BASE_URL =
  import.meta.env.VITE_TRAVERSE_BASE_URL ??
  import.meta.env.VITE_TRAVERSE_RUNTIME_URL ??
  'http://127.0.0.1:8787'
const WORKSPACE = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'
const CAPABILITY_ID = import.meta.env.VITE_TRAVERSE_CAPABILITY_ID ?? 'doc-approval.analyze'
const DOCUMENT_MAX_LENGTH = 10000

function App() {
  const [document, setDocument] = useState('')
  const [runtimeStatus, setRuntimeStatus] = useState<'checking' | 'online' | 'offline'>('checking')

  const client = useMemo(() => createTraverseClient(BASE_URL), [])
  const { state, run, reset } = useExecution(client, WORKSPACE)

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

  const isRunning = state.phase === 'loading' || state.phase === 'polling'
  const canSubmit = document.trim().length > 0 && runtimeStatus === 'online' && !isRunning

  const handleSubmit = useCallback((e?: React.FormEvent) => {
    e?.preventDefault()
    if (!canSubmit) return
    run(CAPABILITY_ID, { document })
  }, [canSubmit, run, document])

  const handleReset = useCallback(() => {
    reset()
    setDocument('')
  }, [reset])

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
          Doc Approval
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '1.05rem' }}>
          Submit documents for AI analysis via the Traverse runtime
        </p>
      </header>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <HealthIndicator
          baseUrl={BASE_URL}
          workspace={WORKSPACE}
          capabilityId={CAPABILITY_ID}
          status={runtimeStatus}
        />

        <DocumentInput
          document={document}
          maxLength={DOCUMENT_MAX_LENGTH}
          canSubmit={canSubmit}
          isRunning={isRunning}
          runtimeOffline={runtimeStatus === 'offline'}
          onChange={setDocument}
          onSubmit={handleSubmit}
        />

        <AnalysisResult
          state={state}
          runtimeOffline={runtimeStatus === 'offline'}
          onReset={handleReset}
        />
      </div>
    </div>
  )
}

export default App
