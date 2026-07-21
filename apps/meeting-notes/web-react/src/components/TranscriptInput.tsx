interface TranscriptInputProps {
  transcript: string
  maxLength: number
  canSubmit: boolean
  isRunning: boolean
  runtimeUnavailable: boolean
  onChange: (value: string) => void
  onSubmit: (e?: React.FormEvent) => void
}

export function TranscriptInput({
  transcript,
  maxLength,
  canSubmit,
  isRunning,
  runtimeUnavailable,
  onChange,
  onSubmit,
}: TranscriptInputProps) {
  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault()
      onSubmit()
    }
  }

  return (
    <section className="glass-panel" style={{ padding: '24px' }}>
      <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
        Meeting Transcript
      </h2>
      <form onSubmit={onSubmit}>
        <div style={{ marginBottom: '20px' }}>
          <label htmlFor="transcript-input" style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '8px', fontWeight: 500 }}>
            Transcript Text
          </label>
          <textarea
            id="transcript-input"
            className="note-textarea"
            value={transcript}
            onChange={(e) => onChange(e.target.value.slice(0, maxLength))}
            onKeyDown={handleKeyDown}
            placeholder="Paste the full meeting transcript…"
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
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '6px', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
            <span>{transcript.length} / {maxLength}</span>
            <span>⌘/Ctrl + Enter to submit</span>
          </div>
        </div>
        <button
          type="submit"
          className="btn-glow"
          disabled={!canSubmit}
          style={{ width: '100%' }}
        >
          {isRunning ? 'Processing…' : 'Process Transcript'}
        </button>
        {runtimeUnavailable && (
          <p role="status" style={{ marginTop: '12px', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Embedded runtime unavailable — sync the meeting-notes bundle (
            <code>bash scripts/ci/sync_web_meeting_notes_bundle.sh</code>) before submitting.
          </p>
        )}
      </form>
    </section>
  )
}
