import type { ExecutionState } from '../hooks/useExecution'
import type { ActionItem, Decision } from '../client/traverseOutput'
import { parseMeetingNotesOutput } from '../client/traverseOutput'

interface MeetingResultProps {
  state: ExecutionState
  runtimeOffline: boolean
  onReset: () => void
}

export function MeetingResult({ state, runtimeOffline, onReset }: MeetingResultProps) {
  const showReset = state.phase === 'succeeded' || state.phase === 'failed'

  return (
    <section className="glass-panel" style={{ padding: '24px', minHeight: '180px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>
          Output
        </h2>
        {showReset && (
          <button type="button" className="btn-glow" onClick={onReset} style={{ padding: '8px 16px', fontSize: '0.85rem' }}>
            Reset
          </button>
        )}
      </div>

      {runtimeOffline && state.phase === 'idle' && (
        <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem', textAlign: 'center', paddingTop: '32px' }}>
          Connect to the Traverse runtime to see meeting notes output here.
        </div>
      )}

      {!runtimeOffline && state.phase === 'idle' && (
        <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem', textAlign: 'center', paddingTop: '32px' }}>
          Submit a transcript above to extract action items and decisions.
        </div>
      )}

      {state.phase === 'loading' && (
        <div style={{ color: 'var(--text-secondary)' }}>Starting processing…</div>
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
        const output = parseMeetingNotesOutput(state.result.output)
        return output ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <ActionItemsSection items={output.action_items} />
            <DecisionsSection items={output.decisions} />
            <StringListSection label="Follow-ups" items={output.follow_ups} />
            <OutputField label="Summary" value={output.summary} />
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

function sectionLabel(label: string) {
  return (
    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>
      {label}
    </div>
  )
}

function EmptyRecorded() {
  return <div style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>None recorded</div>
}

function OutputField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      {sectionLabel(label)}
      <div style={{ fontSize: '1rem', color: 'var(--text-primary)', lineHeight: 1.5 }}>{value}</div>
    </div>
  )
}

function Badge({ children }: { children: string }) {
  return (
    <span style={{ padding: '2px 10px', background: 'rgba(139,92,246,0.15)', color: 'var(--color-accent)', borderRadius: '20px', fontSize: '0.8rem' }}>
      {children}
    </span>
  )
}

function ActionItemsSection({ items }: { items: ActionItem[] }) {
  return (
    <div>
      {sectionLabel('Action Items')}
      {items.length === 0 ? (
        <EmptyRecorded />
      ) : (
        <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {items.map((item, index) => (
            <li key={`${item.task}-${index}`} style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px', color: 'var(--text-primary)' }}>
                <span aria-hidden="true" style={{ color: 'var(--color-accent)' }}>☐</span>
                <span>{item.task}</span>
              </div>
              {(item.owner || item.due) && (
                <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', paddingLeft: '22px' }}>
                  {item.owner && <Badge>{item.owner}</Badge>}
                  {item.due && <Badge>{`due ${item.due}`}</Badge>}
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function DecisionsSection({ items }: { items: Decision[] }) {
  return (
    <div>
      {sectionLabel('Decisions')}
      {items.length === 0 ? (
        <EmptyRecorded />
      ) : (
        <ul style={{ margin: 0, paddingLeft: '18px', display: 'flex', flexDirection: 'column', gap: '8px', color: 'var(--text-primary)' }}>
          {items.map((item, index) => (
            <li key={`${item.text}-${index}`}>
              {item.text}
              {item.made_by && (
                <span style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}> — decided by {item.made_by}</span>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function StringListSection({ label, items }: { label: string; items: string[] }) {
  return (
    <div>
      {sectionLabel(label)}
      {items.length === 0 ? (
        <EmptyRecorded />
      ) : (
        <ul style={{ margin: 0, paddingLeft: '18px', display: 'flex', flexDirection: 'column', gap: '6px', color: 'var(--text-primary)' }}>
          {items.map((item, index) => (
            <li key={`${item}-${index}`}>{item}</li>
          ))}
        </ul>
      )}
    </div>
  )
}
