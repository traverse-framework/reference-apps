/**
 * Minimal deterministic WASI `preview1` shim covering exactly the
 * `wasi_snapshot_preview1` surface in the Traverse Host ABI whitelist
 * (`fd_read`, `fd_write`, `proc_exit`; see `hostAbi.ts`). No filesystem, no
 * network, no environment, no clocks, no randomness — deny-by-default,
 * mirroring the native `WasmExecutor`'s `WasiCtxBuilder` configuration
 * (stdin = input JSON bytes, stdout = captured buffer).
 *
 * Any capability module that requires a broader WASI surface (args,
 * environ, clocks, filesystem) is already outside the Traverse Host ABI
 * whitelist and would be rejected by the native runtime's own import
 * validation before this shim would ever see it (spec `064`).
 */
/** Thrown by `proc_exit`; unwinds the synchronous WASM call. */
export declare class WasiExit extends Error {
    readonly code: number;
    constructor(code: number);
}
/** Mutable memory handle, populated once the WASM instance is created. */
export interface WasiMemoryRef {
    memory: WebAssembly.Memory | null;
}
/** Captured stdio pipes for one execution. */
export declare class WasiPipes {
    private readonly stdin;
    private stdinOffset;
    private readonly stdoutChunks;
    constructor(stdinBytes: Uint8Array);
    readStdin(maxLength: number): Uint8Array;
    writeStdout(bytes: Uint8Array): void;
    stdoutBytes(): Uint8Array;
}
/**
 * Builds the `wasi_snapshot_preview1` import object for one execution.
 * `memoryRef.memory` must be set to the instantiated module's exported
 * memory before any of these functions are invoked.
 */
export declare function createWasiPreview1Imports(pipes: WasiPipes, memoryRef: WasiMemoryRef): WebAssembly.ModuleImports;
