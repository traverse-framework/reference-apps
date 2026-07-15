/**
 * Shared deterministic embedder state: identity, counters, subscribers,
 * event history, and the compatible-capability lifecycle table. Both
 * `EmbedderTestDouble` and `BundleEmbedder` delegate here so their public
 * boundary behavior — event envelope, deterministic identifiers, and
 * compatible lifecycle — is identical (mirrors the Rust SDK's `EmbedderCore`).
 */
import { EMBEDDER_API_VERSION, EMBEDDER_CONFORMANCE_VERSION, EVENT_SCHEMA_VERSION, PACKAGE_NAME, PACKAGE_VERSION, SUPPORTED_BUNDLE_SCHEMA_VERSIONS, embedderError, errorValue, paddedId, runtimeStoppedError, } from "./types.js";
export class EmbedderCore {
    workspaceId;
    appId;
    appVersion;
    platform;
    compatibleTargets;
    instances = new Map();
    subscribers = [];
    history = [];
    nextEvent = 0;
    nextSession = 0;
    nextRequest = 0;
    nextInstance = 0;
    stopped = false;
    constructor(workspaceId, appId, appVersion, platform, compatibleTargets) {
        this.workspaceId = workspaceId;
        this.appId = appId;
        this.appVersion = appVersion;
        this.platform = platform;
        this.compatibleTargets = compatibleTargets;
    }
    nextSessionId() {
        this.nextSession += 1;
        return paddedId("sess", this.nextSession);
    }
    nextRequestId() {
        this.nextRequest += 1;
        return paddedId("req", this.nextRequest);
    }
    nextInstanceId() {
        this.nextInstance += 1;
        return paddedId("inst", this.nextInstance);
    }
    emit(eventType, sessionId, data) {
        this.nextEvent += 1;
        const event = {
            kind: "embedder_event",
            schema_version: EVENT_SCHEMA_VERSION,
            embedder_api_version: EMBEDDER_API_VERSION,
            event_id: paddedId("evt", this.nextEvent),
            sequence: this.nextEvent,
            event_type: eventType,
            workspace_id: this.workspaceId,
            app_id: this.appId,
            session_id: sessionId,
            data,
        };
        for (const subscriber of this.subscribers) {
            subscriber(event);
        }
        this.history.push(event);
    }
    subscribe(callback) {
        for (const event of this.history) {
            callback(event);
        }
        this.subscribers.push(callback);
    }
    emitErrorEvent(sessionId, error, data) {
        this.emit("error", sessionId, { ...data, error: errorValue(error) });
    }
    rejectedSubmit(targetId, error) {
        this.emitErrorEvent(null, error, { target_id: targetId });
        return { sessionId: null, status: "rejected", error };
    }
    startCompatible(capabilityId, input) {
        let error = null;
        if (this.stopped) {
            error = runtimeStoppedError();
        }
        else {
            const platforms = this.compatibleTargets.get(capabilityId);
            if (platforms === undefined) {
                error = embedderError("capability_not_compatible", `capability '${capabilityId}' is not a compatible-mode capability in this bundle`);
            }
            else if (!platforms.includes(this.platform)) {
                error = embedderError("platform_not_supported", `capability '${capabilityId}' permits platforms [${platforms.join(", ")}] ` +
                    `but this embedder runs on '${this.platform}'`);
            }
        }
        if (error !== null) {
            this.emitErrorEvent(null, error, { capability_id: capabilityId });
            return { instanceId: null, status: "error", error };
        }
        const instanceId = this.nextInstanceId();
        this.instances.set(instanceId, { capabilityId, state: "started" });
        this.emit("state_changed", null, {
            capability_id: capabilityId,
            instance_id: instanceId,
            state: "started",
            previous_state: null,
            input,
        });
        return { instanceId, status: "started", error: null };
    }
    transitionCompatible(capabilityId, instanceId, targetState) {
        if (this.stopped) {
            const error = runtimeStoppedError();
            this.emitErrorEvent(null, error, { capability_id: capabilityId });
            return { status: "error", error };
        }
        let selected;
        if (instanceId !== null) {
            const instance = this.instances.get(instanceId);
            if (instance === undefined || instance.capabilityId !== capabilityId) {
                const error = embedderError("instance_not_found", `no instance '${instanceId}' exists for capability '${capabilityId}'`);
                this.emitErrorEvent(null, error, {
                    capability_id: capabilityId,
                    instance_id: instanceId,
                });
                return { status: "error", error };
            }
            if (instance.state !== "started") {
                const error = embedderError("instance_not_running", `instance '${instanceId}' of capability '${capabilityId}' is not running`);
                this.emitErrorEvent(null, error, {
                    capability_id: capabilityId,
                    instance_id: instanceId,
                });
                return { status: "error", error };
            }
            selected = [instanceId];
        }
        else {
            selected = [...this.instances.entries()]
                .filter(([, instance]) => instance.capabilityId === capabilityId && instance.state === "started")
                .map(([id]) => id);
        }
        if (selected.length === 0) {
            const error = embedderError("instance_not_running", `capability '${capabilityId}' has no running instances`);
            this.emitErrorEvent(null, error, { capability_id: capabilityId });
            return { status: "error", error };
        }
        for (const id of selected) {
            this.setInstanceState(id, targetState);
        }
        return { status: targetState, error: null };
    }
    setInstanceState(instanceId, targetState) {
        const instance = this.instances.get(instanceId);
        if (instance === undefined) {
            return;
        }
        const previous = instance.state;
        instance.state = targetState;
        this.emit("state_changed", null, {
            capability_id: instance.capabilityId,
            instance_id: instanceId,
            state: targetState,
            previous_state: previous,
        });
    }
    shutdown() {
        if (this.stopped) {
            return { killedInstances: 0 };
        }
        const running = [...this.instances.entries()]
            .filter(([, instance]) => instance.state === "started")
            .map(([id]) => id);
        for (const id of running) {
            this.setInstanceState(id, "killed");
        }
        this.stopped = true;
        return { killedInstances: running.length };
    }
    evidence(runtimeImplementation, wasmComponents) {
        return {
            kind: "embedder_release_evidence",
            schema_version: EVENT_SCHEMA_VERSION,
            package: { name: PACKAGE_NAME, version: PACKAGE_VERSION },
            embedder_api_version: EMBEDDER_API_VERSION,
            conformance_version: EMBEDDER_CONFORMANCE_VERSION,
            runtime: { implementation: runtimeImplementation },
            supported_bundle_schema_versions: [...SUPPORTED_BUNDLE_SCHEMA_VERSIONS],
            bundle: {
                app_id: this.appId,
                app_version: this.appVersion,
                wasm_components: wasmComponents,
            },
            workspace_id: this.workspaceId,
            platform: this.platform,
        };
    }
}
