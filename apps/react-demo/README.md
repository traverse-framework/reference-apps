# Traverse React Demo

Checked-in React browser demo for Traverse expedition planning.

Canonical home: **`traverse-framework/reference-apps`** (`apps/react-demo/`).

What it does:

- renders one approved expedition flow
- allows one approved request submission path
- shows ordered runtime state updates from the live local browser adapter
- shows the final trace snapshot and output panel after the stream completes

## Local live run

Requires a Traverse checkout with `traverse-cli`:

```bash
export TRAVERSE_REPO=/path/to/Traverse
(cd "$TRAVERSE_REPO" && cargo run -p traverse-cli -- browser-adapter serve --bind 127.0.0.1:4174)
node apps/react-demo/server.mjs --adapter http://127.0.0.1:4174 --port 4173
```

Open `http://127.0.0.1:4173`.

## Fallback preview

```bash
python3 -m http.server 4173 --directory apps/react-demo
```

## Validation

```bash
bash scripts/ci/react_demo_smoke.sh
# optional live path:
export TRAVERSE_REPO=/path/to/Traverse
bash scripts/ci/react_demo_live_adapter_smoke.sh
```

Runtime docs: [browser-adapter.md](https://github.com/traverse-framework/Traverse/blob/main/docs/browser-adapter.md), [quickstart](https://github.com/traverse-framework/Traverse/blob/main/quickstart.md).
