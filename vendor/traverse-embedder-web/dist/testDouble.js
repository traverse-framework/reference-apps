/**
 * Deterministic in-memory test double implementing the same public boundary
 * as the production embedder (spec 068 FR-006). It shares the event
 * envelope, identifier scheme, compatible lifecycle, and shutdown semantics;
 * only capability execution is replaced with scripted results. It contains
 * no business logic.
 */
import { EmbedderCore } from "./core.js";
import { embedderError, runtimeStoppedError } from "./types.js";
export class EmbedderTestDouble {
    core;
    scripted = new Map();
    constructor(config = {}) {
        this.core = new EmbedderCore(config.workspaceId ?? "local-default", config.appId ?? "test-app", config.appVersion ?? "1.0.0", config.platform ?? "web", new Map());
    }
    /** Scripts `submit(targetId, _)` to succeed with `output`. */
    withTargetOutput(targetId, output) {
        this.scripted.set(targetId, { kind: "output", output });
        return this;
    }
    /** Scripts `submit(targetId, _)` to fail with a runtime-shaped error. */
    withTargetError(targetId, code, message) {
        this.scripted.set(targetId, { kind: "error", code, message });
        return this;
    }
    /** Declares a compatible-mode capability with a platform allowlist. */
    withCompatibleTarget(capabilityId, platforms) {
        this.core.compatibleTargets.set(capabilityId, platforms);
        return this;
    }
    submit(targetId, input) {
        void input;
        if (this.core.stopped) {
            return this.core.rejectedSubmit(targetId, runtimeStoppedError());
        }
        const result = this.scripted.get(targetId);
        if (result === undefined) {
            return this.core.rejectedSubmit(targetId, embedderError("target_not_found", `'${targetId}' is neither a bundled workflow nor a bundled capability`));
        }
        const sessionId = this.core.nextSessionId();
        const requestId = this.core.nextRequestId();
        const executionId = `exec_${requestId}`;
        this.core.emit("capability_invoked", sessionId, {
            execution_id: executionId,
            capability_id: targetId,
            capability_version: "1.0.0",
        });
        if (result.kind === "output") {
            this.core.emit("capability_result", sessionId, {
                execution_id: executionId,
                capability_id: targetId,
                status: "completed",
                output: result.output,
            });
        }
        else {
            this.core.emit("error", sessionId, {
                execution_id: executionId,
                capability_id: targetId,
                status: "error",
                error: { code: result.code, message: result.message, details: {} },
            });
        }
        return { sessionId, status: "accepted", error: null };
    }
    subscribe(callback) {
        this.core.subscribe(callback);
    }
    startCompatible(capabilityId, input) {
        return this.core.startCompatible(capabilityId, input);
    }
    stopCompatible(capabilityId, instanceId = null) {
        return this.core.transitionCompatible(capabilityId, instanceId, "stopped");
    }
    killCompatible(capabilityId, instanceId = null) {
        return this.core.transitionCompatible(capabilityId, instanceId, "killed");
    }
    shutdown() {
        return this.core.shutdown();
    }
    releaseEvidence() {
        return this.core.evidence("test-double", []);
    }
}
