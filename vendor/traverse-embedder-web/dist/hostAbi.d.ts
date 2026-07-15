/**
 * Traverse Host ABI import whitelist (mirrors
 * `crates/traverse-runtime/src/executor/host_abi_v1.json`). A bundled WASM
 * capability module may declare only these imports; every other import is
 * rejected deterministically before the module is instantiated — the
 * browser executor never links an unauthorized host function (deny-by-
 * default, matching the native `WasmExecutor`'s no-filesystem,
 * no-network, no-env-vars posture).
 */
export interface HostAbiImport {
    readonly module: string;
    readonly name: string;
}
/** Traverse Host ABI version this package validates modules against. */
export declare const SUPPORTED_HOST_ABI_VERSION = "1.0.0";
export declare const HOST_ABI_V1_WHITELIST: readonly HostAbiImport[];
/**
 * Returns the first function import outside the host ABI whitelist, or
 * `null` when every function import is authorized.
 */
export declare function findUnauthorizedImport(module: WebAssembly.Module): HostAbiImport | null;
