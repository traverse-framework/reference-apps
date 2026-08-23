import type { PresentationState } from 'event-ui-conformance'

export interface ReviewPanelProps {
  presentationState: PresentationState | null | undefined
  /** Runtime-provided candidate fields only — never invent thresholds in UI. */
  candidates: unknown
  onAccept: () => void
  onReject: () => void
}

/**
 * Human-review chrome for Spec 003 FR-004. Shown when the public event stream
 * maps to `blocked` (waiting-for-human). Accept/reject submit via host callbacks
 * that call public embedder APIs — UI does not score confidence.
 */
export function ReviewPanel({
  presentationState,
  candidates,
  onAccept,
  onReject,
}: ReviewPanelProps) {
  if (presentationState !== 'blocked') return null

  return (
    <section
      aria-label="Human review"
      style={{
        marginTop: '1.5rem',
        padding: '1rem 0',
        borderTop: '1px solid #d0d7de',
      }}
    >
      <h2 style={{ fontSize: '1.1rem', margin: '0 0 0.5rem' }}>Review required</h2>
      <p style={{ margin: '0 0 1rem', color: '#57606a' }}>
        Runtime paused for human review. Accept or reject the candidate fields below —
        thresholds stay in the runtime, not in this UI.
      </p>
      <pre
        style={{
          background: '#f6f8fa',
          padding: '0.75rem',
          overflow: 'auto',
          fontSize: '0.85rem',
          marginBottom: '1rem',
        }}
      >
        {JSON.stringify(candidates, null, 2)}
      </pre>
      <div style={{ display: 'flex', gap: '0.75rem' }}>
        <button type="button" onClick={onAccept}>
          Accept
        </button>
        <button type="button" onClick={onReject}>
          Reject
        </button>
      </div>
    </section>
  )
}
