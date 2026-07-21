type RuntimeStatus = 'starting' | 'ready' | 'unavailable'

interface HealthIndicatorProps {
  workspace: string
  workflowId: string
  status: RuntimeStatus
}

export function HealthIndicator({ workspace, workflowId, status }: HealthIndicatorProps) {
  const label =
    status === 'ready' ? 'Ready' : status === 'unavailable' ? 'Unavailable' : 'Starting'
  return (
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
          <div style={{ color: 'var(--text-primary)', marginTop: '4px' }}>Embedded</div>
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
              className={status === 'starting' ? 'status-dot-checking' : undefined}
              style={{
                display: 'inline-block',
                width: '10px',
                height: '10px',
                borderRadius: '50%',
                backgroundColor:
                  status === 'ready' ? '#06b6d4' : status === 'unavailable' ? '#ef4444' : '#64748b',
              }}
            />
            <span style={{ fontSize: '1rem', color: 'var(--text-primary)', fontWeight: 500 }}>
              {label}
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
        Workspace: <strong>{workspace}</strong> · Workflow: <strong>{workflowId}</strong>
      </div>
    </section>
  )
}

export type { RuntimeStatus }
