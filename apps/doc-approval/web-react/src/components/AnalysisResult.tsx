import type { ExecutionState } from '../hooks/useExecution'
import { parseAnalysisOutput } from '../client/traverseOutput'

interface AnalysisResultProps {
  state: ExecutionState
  runtimeOffline: boolean
  onReset: () => void
}

export function AnalysisResult({ state, runtimeOffline, onReset }: AnalysisResultProps) {
  const showReset = state.phase === 'succeeded' || state.phase === 'failed'

  return (
    <section className="glass-panel" style={{ padding: '24px', minHeight: '180px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>
          Analysis Result
        </h2>
        {showReset && (
          <button type="button" className="btn-glow" onClick={onReset} style={{ padding: '8px 16px', fontSize: '0.85rem' }}>
            Reset
          </button>
        )}
      </div>

      {runtimeOffline && state.phase === 'idle' && (
        <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem', textAlign: 'center', paddingTop: '32px' }}>
          Connect to the Traverse runtime to see analysis output here.
        </div>
      )}

      {!runtimeOffline && state.phase === 'idle' && (
        <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem', textAlign: 'center', paddingTop: '32px' }}>
          Submit a document above to start analysis.
        </div>
      )}

      {state.phase === 'loading' && (
        <div style={{ color: 'var(--text-secondary)' }}>Starting analysis…</div>
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
        const output = parseAnalysisOutput(state.result.output)
        return output ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <OutputField label="Document Type" value={output.docType} />
            <OutputField label="Recommendation" value={output.recommendation} />
            <OutputField label="Confidence" value={formatConfidence(output.confidence)} />
            <TagList label="Parties" items={output.parties} />
            <TagList label="Amounts" items={output.amounts} />
          </div>
        ) : (
          <pre style={{ background: 'rgba(0,0,0,0.4)', padding: '16px', borderRadius: '6px', fontSize: '0.85rem', color: 'var(--text-primary)', overflow: 'auto' }}>
            {JSON.stringify(state.result.output, null, 2)}
          </pre>
        )
      })()}
    </section>
  )
}

function formatConfidence(value: number): string {
  if (value >= 0 && value <= 1) return `${Math.round(value * 100)}%`
  return String(value)
}

function OutputField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '4px' }}>{label}</div>
      <div style={{ fontSize: '1rem', color: 'var(--text-primary)' }}>{value}</div>
    </div>
  )
}

function TagList({ label, items }: { label: string; items: string[] }) {
  return (
    <div>
      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '6px' }}>{label}</div>
      {items.length === 0 ? (
        <div style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>None</div>
      ) : (
        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
          {items.map(item => (
            <span key={item} style={{ padding: '2px 10px', background: 'rgba(139,92,246,0.15)', color: 'var(--color-accent)', borderRadius: '20px', fontSize: '0.85rem' }}>
              {item}
            </span>
          ))}
        </div>
      )}
    </div>
  )
}
