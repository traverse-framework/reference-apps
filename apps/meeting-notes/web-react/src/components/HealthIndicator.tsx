type RuntimeStatus = 'checking' | 'online' | 'offline'

interface HealthIndicatorProps {
  baseUrl: string
  workspace: string
  capabilityId: string
  status: RuntimeStatus
}

export function HealthIndicator({ baseUrl, workspace, capabilityId, status }: HealthIndicatorProps) {
  return (
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
            {baseUrl}
          </div>
        </div>
        <div>
          <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Runtime Status
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
            <span
              className={status === 'checking' ? 'status-dot-checking' : undefined}
              style={{
                display: 'inline-block',
                width: '10px',
                height: '10px',
                borderRadius: '50%',
                backgroundColor: status === 'online' ? '#06b6d4' : status === 'offline' ? '#ef4444' : '#64748b',
              }}
            />
            <span style={{ fontSize: '1rem', color: 'var(--text-primary)', fontWeight: 500 }}>
              {status === 'online' ? 'Online' : status === 'offline' ? 'Offline' : 'Checking...'}
            </span>
          </div>
        </div>
      </div>
      <div style={{ marginTop: '20px', paddingTop: '16px', borderTop: '1px solid rgba(255,255,255,0.05)', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
        Workspace: <strong>{workspace}</strong> · Capability: <strong>{capabilityId}</strong>
      </div>
    </section>
  )
}

export type { RuntimeStatus }
