import type { EmbedderError, JsonValue } from "./types.js";
/** Thrown when a bundle is rejected at the embedder boundary. */
export declare class BundleRejectedError extends Error {
    readonly embedderError: EmbedderError;
    constructor(error: EmbedderError);
}
/** One bundled component reference parsed from the app manifest. */
export interface BundleComponentSummary {
    readonly componentId: string;
    readonly version: string;
    readonly digest: string;
    readonly manifestPath: string;
}
/** One bundled workflow reference parsed from the app manifest. */
export interface BundleWorkflowSummary {
    readonly workflowId: string;
    readonly workflowVersion: string;
    readonly path: string;
}
/** Deterministic bundle compatibility summary (spec 068 NFR-001). */
export interface BundleCompatibility {
    readonly appId: string;
    readonly appVersion: string;
    readonly schemaVersion: string;
    readonly components: readonly BundleComponentSummary[];
    readonly workflowIds: readonly string[];
    readonly workflows: readonly BundleWorkflowSummary[];
}
export declare function asRecord(value: JsonValue | undefined): {
    [key: string]: JsonValue;
} | null;
export declare function requiredString(record: {
    [key: string]: JsonValue;
}, key: string, context: string): string;
export declare function optionalString(record: {
    [key: string]: JsonValue;
}, key: string): string | null;
export declare const SHA256_DIGEST_PATTERN: RegExp;
/**
 * Parses and deterministically validates an application bundle manifest
 * (spec `044-application-bundle-manifest`) for embedder compatibility:
 * schema version support, component identity, and sha-256 digest metadata.
 * Rejection never falls back to a sidecar (spec 068 NFR-001).
 *
 * @throws {BundleRejectedError} with a stable `EmbedderErrorCode`.
 */
export declare function validateBundleCompatibility(appManifest: string | JsonValue): BundleCompatibility;
/**
 * Verifies bundled artifact bytes against declared sha-256 digest metadata
 * using WebCrypto (browser) or the Node.js webcrypto implementation.
 *
 * @throws {BundleRejectedError} with `bundle_load_failed` on mismatch.
 */
export declare function verifyArtifactDigest(bytes: Uint8Array, declaredDigest: string, artifactLabel: string): Promise<void>;
