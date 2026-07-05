# trace-explorer (Web React)

Standalone developer tool for inspecting Traverse execution traces via spec 033 `GET /v1/workspaces/{workspace_id}/traces/{execution_id}`.

## Usage

1. Start the Traverse runtime (`cargo run -p traverse-cli -- serve`)
2. Run a workflow in traverse-starter and copy the `execution_id` from the polling UI
3. From repo root: `npm run dev -w apps/trace-explorer/web-react`
4. Paste the execution ID → **Load Trace**

## URL sharing

```
http://localhost:5173/?runtime=http://127.0.0.1:8787&workspace=local-default&execution_id=exec_abc123
```

## Configuration

| Variable | Default |
|---|---|
| `VITE_TRAVERSE_BASE_URL` | `http://127.0.0.1:8787` |
| `VITE_TRAVERSE_WORKSPACE` | `local-default` |

See [docs/design-language.md](../../../docs/design-language.md) for shared UI zones.
