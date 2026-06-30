import { useMemo } from 'react'
import { createTraverseClient } from './client/traverseClient'
import { useExecution } from './hooks/useExecution'

const BASE_URL = import.meta.env.VITE_TRAVERSE_BASE_URL ?? 'http://127.0.0.1:8787'
const WORKSPACE = import.meta.env.VITE_TRAVERSE_WORKSPACE ?? 'local-default'

function App() {
  const client = useMemo(() => createTraverseClient(BASE_URL), [])
  const { state, run } = useExecution(client, WORKSPACE)

  const handleRun = () => {
    run('youaskm3.answer', { question: 'What is Traverse?' })
  }

  return (
    <main>
      <h1>youaskm3</h1>
      <p>Runtime: {BASE_URL} · Workspace: {WORKSPACE}</p>

      <button onClick={handleRun} disabled={state.phase === 'loading' || state.phase === 'polling'}>
        Run
      </button>

      {state.phase === 'loading' && <p>Starting…</p>}
      {state.phase === 'polling' && <p>Polling {state.executionId}…</p>}
      {state.phase === 'succeeded' && (
        <div>
          <p>Done: {JSON.stringify(state.result.output)}</p>
          {state.trace.length > 0 && <p>Trace events: {state.trace.length}</p>}
        </div>
      )}
      {state.phase === 'failed' && <p>Error: {state.error}</p>}
    </main>
  )
}

export default App
