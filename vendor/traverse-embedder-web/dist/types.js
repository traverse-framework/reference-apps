/**
 * Shared wire types for the `embedder-api/1.0.0` boundary (spec 057). These
 * are wire-identical in field naming to the Rust `traverse-embedder` crate
 * so every platform observes the same operations, event envelope, and error
 * codes (spec 057 FR-003).
 */
/** Implemented embedder API version (spec 057 IDL `$id` suffix). */
export const EMBEDDER_API_VERSION = "1.0.0";
/** Conformance suite revision this package certifies against (spec 057). */
export const EMBEDDER_CONFORMANCE_VERSION = "1.0.0";
/** Implemented additive public Trace API companion version (spec 517). */
export const EMBEDDED_TRACE_API_VERSION = "1.0.0";
/** Maximum public trace records retained by one embedded session. */
export const EMBEDDED_TRACE_RETENTION_LIMIT = 100;
/** Largest `trace.list` page returned by this package. */
export const EMBEDDED_TRACE_MAX_PAGE_SIZE = 100;
/** Application bundle manifest `schema_version` values this package accepts. */
export const SUPPORTED_BUNDLE_SCHEMA_VERSIONS = ["1.0.0"];
export const EVENT_SCHEMA_VERSION = "1.0.0";
export const PACKAGE_NAME = "traverse-embedder-web";
export const PACKAGE_VERSION = "0.7.0";
export function embedderError(code, message) {
    return { code, message };
}
export function errorValue(error) {
    return { code: error.code, message: error.message };
}
export function paddedId(prefix, counter) {
    return `${prefix}-${String(counter).padStart(8, "0")}`;
}
export function runtimeStoppedError() {
    return embedderError("runtime_stopped", "the embedded runtime was shut down and accepts no further operations");
}
