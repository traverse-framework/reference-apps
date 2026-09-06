/**
 * Browser client for the Spec 115 verified-entrypoint HTTP boundary.
 *
 * The server owns registry synchronization, artifact materialization, digest
 * verification, and execution. This client deliberately sends only an exact
 * identity and a RuntimeRequest; it never accepts an artifact URL or bytes.
 */
export interface VerifiedEntrypointRequest {
    readonly id: string;
    readonly version: string;
    readonly request: Record<string, unknown>;
}
export interface VerifiedEntrypointResponse {
    readonly status: "completed" | "error";
    readonly request_id: string;
    readonly execution_id: string;
    readonly trace_ref: string;
    readonly output: unknown;
    readonly error: {
        readonly code: string;
        readonly message: string;
    } | null;
    readonly trace: unknown;
}
export declare class VerifiedEntrypointError extends Error {
    readonly code: string;
    constructor(code: string, message: string);
}
export type VerifiedEntrypointFetch = (input: string, init: RequestInit) => Promise<Response>;
/** Execute one capability whose artifact was verified by the serving host. */
export declare function executeVerifiedEntrypoint(fetcher: VerifiedEntrypointFetch, serverUrl: string, request: VerifiedEntrypointRequest): Promise<VerifiedEntrypointResponse>;
