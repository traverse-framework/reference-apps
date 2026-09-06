/**
 * Browser client for the Spec 115 verified-entrypoint HTTP boundary.
 *
 * The server owns registry synchronization, artifact materialization, digest
 * verification, and execution. This client deliberately sends only an exact
 * identity and a RuntimeRequest; it never accepts an artifact URL or bytes.
 */
export class VerifiedEntrypointError extends Error {
    code;
    constructor(code, message) {
        super(message);
        this.name = "VerifiedEntrypointError";
        this.code = code;
    }
}
function exact(value, label) {
    const normalized = value.trim();
    if (normalized.length === 0) {
        throw new VerifiedEntrypointError("invalid_entrypoint_request", `${label} is required`);
    }
    return normalized;
}
function endpointFor(serverUrl) {
    return `${exact(serverUrl, "server URL").replace(/\/+$/, "")}/v1/entrypoints/execute`;
}
/** Execute one capability whose artifact was verified by the serving host. */
export async function executeVerifiedEntrypoint(fetcher, serverUrl, request) {
    const id = exact(request.id, "capability id");
    const version = exact(request.version, "capability version");
    const response = await fetcher(endpointFor(serverUrl), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ entrypoint_kind: "capability", id, version, request: request.request }),
    });
    const body = await response.json();
    if (!response.ok) {
        const problem = body;
        throw new VerifiedEntrypointError(typeof problem.traverse_code === "string" ? problem.traverse_code : "entrypoint_execute_failed", typeof problem.detail === "string" ? problem.detail : `verified entrypoint request failed: HTTP ${response.status}`);
    }
    return body;
}
