interface DocumentInputProps {
  document: string
  maxLength: number
  canSubmit: boolean
  isRunning: boolean
  runtimeOffline: boolean
  onChange: (value: string) => void
  onSubmit: (e?: React.FormEvent) => void
}

export function DocumentInput({
  document,
  maxLength,
  canSubmit,
  isRunning,
  runtimeOffline,
  onChange,
  onSubmit,
}: DocumentInputProps) {
  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault()
      onSubmit()
    }
  }

  return (
    <section className="glass-panel" style={{ padding: '24px' }}>
      <h2 style={{ fontSize: '1.25rem', marginBottom: '16px', fontWeight: 600 }}>
        Submit Document
      </h2>
      <form onSubmit={onSubmit}>
        <div style={{ marginBottom: '20px' }}>
          <label htmlFor="document-input" style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '8px', fontWeight: 500 }}>
            Document Text
          </label>
          <textarea
            id="document-input"
            className="note-textarea"
            value={document}
            onChange={(e) => onChange(e.target.value.slice(0, maxLength))}
            onKeyDown={handleKeyDown}
            placeholder="Paste or type document text for AI analysis..."
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
            <span>{document.length} / {maxLength}</span>
            <span>⌘/Ctrl + Enter to submit</span>
          </div>
        </div>
        <button
          type="submit"
          className="btn-glow"
          disabled={!canSubmit}
          style={{ width: '100%' }}
        >
          {isRunning ? 'Analyzing…' : 'Analyze Document'}
        </button>
        {runtimeOffline && (
          <p role="status" style={{ marginTop: '12px', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            The runtime is offline. Start it with{' '}
            <code>cargo run -p traverse-cli -- serve</code> before submitting a document.
          </p>
        )}
      </form>
    </section>
  )
}
