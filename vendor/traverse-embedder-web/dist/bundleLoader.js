/**
 * Loads application bundle files (manifests, contracts, WASM artifacts) by
 * relative path. `BundleEmbedder` depends only on this interface, so a
 * browser host supplies `FetchBundleLoader` (production) and a Node host
 * (tests, Electron main-process embedding) supplies `NodeFsBundleLoader` —
 * neither is baked into the public API surface (spec 068: no `traverse-cli
 * serve` dependency in the production path).
 */
function dirname(path) {
    const index = path.lastIndexOf("/");
    return index === -1 ? "" : path.slice(0, index);
}
function joinPosix(base, relative) {
    if (relative.startsWith("/") || /^[a-zA-Z]+:/.test(relative)) {
        return relative;
    }
    const segments = `${base}/${relative}`.split("/");
    const resolved = [];
    for (const segment of segments) {
        if (segment === "" || segment === ".") {
            continue;
        }
        if (segment === "..") {
            resolved.pop();
            continue;
        }
        resolved.push(segment);
    }
    return (base.startsWith("/") ? "/" : "") + resolved.join("/");
}
/**
 * Browser bundle loader: resolves paths as URLs relative to the manifest
 * URL and loads them via `fetch`. This is the production loader — no
 * `traverse-cli serve` sidecar is involved.
 */
export class FetchBundleLoader {
    resolve(basePath, relativePath) {
        const documentBase = typeof document !== "undefined" ? document.baseURI : globalThis.location.href;
        return new URL(relativePath, new URL(basePath, documentBase)).toString();
    }
    async loadText(path) {
        const response = await fetch(path);
        if (!response.ok) {
            throw new Error(`failed to fetch '${path}': HTTP ${response.status}`);
        }
        return response.text();
    }
    async loadBytes(path) {
        const response = await fetch(path);
        if (!response.ok) {
            throw new Error(`failed to fetch '${path}': HTTP ${response.status}`);
        }
        return new Uint8Array(await response.arrayBuffer());
    }
}
/**
 * Node.js filesystem bundle loader, for tests and non-browser hosts
 * (Electron main process, server-side prerendering). Uses dynamic `import`
 * so `node:fs` is never a static dependency of the browser entry point.
 */
export class NodeFsBundleLoader {
    resolve(basePath, relativePath) {
        return joinPosix(dirname(basePath), relativePath);
    }
    async loadText(path) {
        const { readFile } = await import("node:fs/promises");
        return readFile(path, "utf8");
    }
    async loadBytes(path) {
        const { readFile } = await import("node:fs/promises");
        const buffer = await readFile(path);
        return new Uint8Array(buffer.buffer, buffer.byteOffset, buffer.byteLength);
    }
}
