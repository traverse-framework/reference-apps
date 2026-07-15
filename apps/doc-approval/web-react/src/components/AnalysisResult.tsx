import type { HostRunResult } from '../host/embeddedHost'

interface AnalysisResultProps {
  result: HostRunResult | null
  submitting: boolean
  runtimeUnavailable: boolean
  onReset: () => void
}

export function AnalysisResult({
  result,
  submitting,
  runtimeUnavailable,
  onReset,
}: AnalysisResultProps) {
  const showReset = Boolean(result)
  const output = result?.output ?? null

  return (
    <section className="glass-panel" style={{ padding: '24px', minHeight: '180px' }}>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '16px',
        }}
      >
        <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Analysis Result</h2>
        {showReset && (
          <button
            type="button"
            className="btn-glow"
            onClick={onReset}
            style={{ padding: '8px 16px', fontSize: '0.85rem' }}
          >
            Reset
          </button>
        )}
      </div>

      {runtimeUnavailable && !result && !submitting && (
        <div
          style={{
            color: 'var(--text-muted)',
            fontSize: '0.95rem',
            textAlign: 'center',
            paddingTop: '32px',
          }}
        >
          Initialize the embedded runtime (manifests #112) to see output here.
        </div>
      )}

      {!runtimeUnavailable && !result && !submitting && (
        <div
          style={{
            color: 'var(--text-muted)',
            fontSize: '0.95rem',
            textAlign: 'center',
            paddingTop: '32px',
          }}
        >
          Submit a document above to start analysis.
        </div>
      )}

      {submitting && <div style={{ color: 'var(--text-secondary)' }}>Running embedded workflow…</div>}

      {result?.error && (
        <div style={{ color: '#ef4444' }}>
          <strong>Error:</strong> {result.error}
        </div>
      )}

      {output && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <OutputField label="Document Type" value={output.docType} />
          <OutputField label="Recommendation" value={output.recommendation} />
          <OutputField label="Confidence" value={formatConfidence(output.confidence)} />
          <TagList label="Parties" items={output.parties} />
          <TagList label="Amounts" items={output.amounts} />
        </div>
      )}

      {!output && result && !result.error && result.rawOutput != null && (
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
  )
}

function formatConfidence(value: number): string {
  if (value >= 0 && value <= 1) return `${Math.round(value * 100)}%`
  return String(value)
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

function TagList({ label, items }: { label: string; items: string[] }) {
  return (
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
        {label}
      </div>
      {items.length === 0 ? (
        <div style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>None</div>
      ) : (
        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
          {items.map((item) => (
            <span
              key={item}
              style={{
                padding: '2px 10px',
                background: 'rgba(139,92,246,0.15)',
                color: 'var(--color-accent)',
                borderRadius: '20px',
                fontSize: '0.85rem',
              }}
            >
              {item}
            </span>
          ))}
        </div>
      )}
    </div>
  )
}
