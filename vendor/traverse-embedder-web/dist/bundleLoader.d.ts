/**
 * Loads application bundle files (manifests, contracts, WASM artifacts) by
 * relative path. `BundleEmbedder` depends only on this interface, so a
 * browser host supplies `FetchBundleLoader` (production) and a Node host
 * (tests, Electron main-process embedding) supplies `NodeFsBundleLoader` —
 * neither is baked into the public API surface (spec 068: no `traverse-cli
 * serve` dependency in the production path).
 */
export interface BundleLoader {
    /** Resolves `relativePath` against the directory containing `basePath`. */
    resolve(basePath: string, relativePath: string): string;
    /** Loads a UTF-8 text file (manifests, contracts, workflow definitions). */
    loadText(path: string): Promise<string>;
    /** Loads raw bytes (WASM artifacts). */
    loadBytes(path: string): Promise<Uint8Array>;
}
/**
 * Browser bundle loader: resolves paths as URLs relative to the manifest
 * URL and loads them via `fetch`. This is the production loader — no
 * `traverse-cli serve` sidecar is involved.
 */
export declare class FetchBundleLoader implements BundleLoader {
    resolve(basePath: string, relativePath: string): string;
    loadText(path: string): Promise<string>;
    loadBytes(path: string): Promise<Uint8Array>;
}
/**
 * Node.js filesystem bundle loader, for tests and non-browser hosts
 * (Electron main process, server-side prerendering). Uses dynamic `import`
 * so `node:fs` is never a static dependency of the browser entry point.
 */
export declare class NodeFsBundleLoader implements BundleLoader {
    resolve(basePath: string, relativePath: string): string;
    loadText(path: string): Promise<string>;
    loadBytes(path: string): Promise<Uint8Array>;
}
