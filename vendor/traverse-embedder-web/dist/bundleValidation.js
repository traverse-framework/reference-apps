/**
 * Deterministic application bundle manifest validation (spec
 * `044-application-bundle-manifest`) and artifact digest verification.
 * Rejection never falls back to a sidecar (spec 068 NFR-001).
 */
import { SUPPORTED_BUNDLE_SCHEMA_VERSIONS, embedderError } from "./types.js";
/** Thrown when a bundle is rejected at the embedder boundary. */
export class BundleRejectedError extends Error {
    embedderError;
    constructor(error) {
        super(`${error.code}: ${error.message}`);
        this.name = "BundleRejectedError";
        this.embedderError = error;
    }
}
export function asRecord(value) {
    if (typeof value === "object" && value !== null && !Array.isArray(value)) {
        return value;
    }
    return null;
}
export function requiredString(record, key, context) {
    const value = record[key];
    if (typeof value !== "string" || value.trim() === "") {
        throw new BundleRejectedError(embedderError("bundle_load_failed", `${context} requires a non-empty string '${key}'`));
    }
    return value;
}
export function optionalString(record, key) {
    const value = record[key];
    return typeof value === "string" ? value : null;
}
export const SHA256_DIGEST_PATTERN = /^sha256:[0-9a-f]{64}$/;
/**
 * Parses and deterministically validates an application bundle manifest
 * (spec `044-application-bundle-manifest`) for embedder compatibility:
 * schema version support, component identity, and sha-256 digest metadata.
 * Rejection never falls back to a sidecar (spec 068 NFR-001).
 *
 * @throws {BundleRejectedError} with a stable `EmbedderErrorCode`.
 */
export function validateBundleCompatibility(appManifest) {
    let parsed;
    if (typeof appManifest === "string") {
        try {
            parsed = JSON.parse(appManifest);
        }
        catch (error) {
            throw new BundleRejectedError(embedderError("bundle_load_failed", `application bundle manifest is not valid JSON: ${String(error)}`));
        }
    }
    else {
        parsed = appManifest;
    }
    const manifest = asRecord(parsed);
    if (manifest === null) {
        throw new BundleRejectedError(embedderError("bundle_load_failed", "application bundle manifest must be a JSON object"));
    }
    const appId = requiredString(manifest, "app_id", "application bundle manifest");
    const appVersion = requiredString(manifest, "version", "application bundle manifest");
    const schemaVersion = requiredString(manifest, "schema_version", "application bundle manifest");
    if (!SUPPORTED_BUNDLE_SCHEMA_VERSIONS.includes(schemaVersion)) {
        throw new BundleRejectedError(embedderError("unsupported_bundle_schema", `bundle declares schema_version '${schemaVersion}' but this package supports ` +
            `[${SUPPORTED_BUNDLE_SCHEMA_VERSIONS.join(", ")}]; no sidecar fallback is attempted`));
    }
    const componentsValue = manifest["components"];
    if (!Array.isArray(componentsValue)) {
        throw new BundleRejectedError(embedderError("bundle_load_failed", "application bundle manifest requires a 'components' array"));
    }
    const components = componentsValue.map((entry, index) => {
        const component = asRecord(entry);
        if (component === null) {
            throw new BundleRejectedError(embedderError("bundle_load_failed", `components[${index}] must be a JSON object`));
        }
        const context = `components[${index}]`;
        const digest = requiredString(component, "digest", context);
        if (!SHA256_DIGEST_PATTERN.test(digest)) {
            throw new BundleRejectedError(embedderError("bundle_load_failed", `${context} declares invalid digest metadata '${digest}'; ` +
                "expected sha256:<64 hex characters>"));
        }
        return {
            componentId: requiredString(component, "component_id", context),
            version: requiredString(component, "version", context),
            digest,
            manifestPath: requiredString(component, "manifest_path", context),
        };
    });
    const workflowsValue = manifest["workflows"];
    const workflowIds = [];
    const workflows = [];
    if (Array.isArray(workflowsValue)) {
        for (const [index, entry] of workflowsValue.entries()) {
            const workflow = asRecord(entry);
            if (workflow === null) {
                throw new BundleRejectedError(embedderError("bundle_load_failed", `workflows[${index}] must be a JSON object`));
            }
            const context = `workflows[${index}]`;
            const workflowId = requiredString(workflow, "workflow_id", context);
            workflowIds.push(workflowId);
            workflows.push({
                workflowId,
                workflowVersion: requiredString(workflow, "workflow_version", context),
                path: requiredString(workflow, "path", context),
            });
        }
    }
    return { appId, appVersion, schemaVersion, components, workflowIds, workflows };
}
/**
 * Verifies bundled artifact bytes against declared sha-256 digest metadata
 * using WebCrypto (browser) or the Node.js webcrypto implementation.
 *
 * @throws {BundleRejectedError} with `bundle_load_failed` on mismatch.
 */
export async function verifyArtifactDigest(bytes, declaredDigest, artifactLabel) {
    if (!SHA256_DIGEST_PATTERN.test(declaredDigest)) {
        throw new BundleRejectedError(embedderError("bundle_load_failed", `${artifactLabel} declares invalid digest metadata '${declaredDigest}'`));
    }
    const digestBytes = await crypto.subtle.digest("SHA-256", bytes.slice().buffer);
    const actual = [...new Uint8Array(digestBytes)]
        .map((byte) => byte.toString(16).padStart(2, "0"))
        .join("");
    const expected = declaredDigest.slice("sha256:".length);
    if (actual !== expected) {
        throw new BundleRejectedError(embedderError("bundle_load_failed", `${artifactLabel} digest mismatch: manifest declares sha256:${expected} ` +
            `but the bundled artifact hashes to sha256:${actual}; ` +
            "no sidecar fallback is attempted"));
    }
}
