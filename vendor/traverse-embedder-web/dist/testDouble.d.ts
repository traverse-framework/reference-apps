import type { CompatibleLifecycleOutcome, CompatibleStartOutcome, EmbeddedTraceApi, EmbeddedTraceApiError, EmbeddedTraceDetail, EmbeddedTracePage, EventCallback, JsonValue, ShutdownOutcome, SubmitOutcome, TraverseEmbedderApi } from "./types.js";
/** Configuration for the deterministic test double. */
export interface EmbedderTestDoubleConfig {
    readonly workspaceId?: string;
    readonly appId?: string;
    readonly appVersion?: string;
    readonly platform?: string;
}
export declare class EmbedderTestDouble implements TraverseEmbedderApi, EmbeddedTraceApi {
    private readonly core;
    private readonly scripted;
    constructor(config?: EmbedderTestDoubleConfig);
    /** Scripts `submit(targetId, _)` to succeed with `output`. */
    withTargetOutput(targetId: string, output: JsonValue): this;
    /** Scripts `submit(targetId, _)` to fail with a runtime-shaped error. */
    withTargetError(targetId: string, code: string, message: string): this;
    /** Declares a compatible-mode capability with a platform allowlist. */
    withCompatibleTarget(capabilityId: string, platforms: readonly string[]): this;
    submit(targetId: string, input: JsonValue): SubmitOutcome;
    subscribe(callback: EventCallback): void;
    embeddedTraceApiVersion(): string;
    traceList(requestedVersion: string, pageSize: number, cursor?: string | null): EmbeddedTracePage | EmbeddedTraceApiError;
    traceGet(requestedVersion: string, traceId: string): EmbeddedTraceDetail | EmbeddedTraceApiError;
    startCompatible(capabilityId: string, input: JsonValue): CompatibleStartOutcome;
    stopCompatible(capabilityId: string, instanceId?: string | null): CompatibleLifecycleOutcome;
    killCompatible(capabilityId: string, instanceId?: string | null): CompatibleLifecycleOutcome;
    shutdown(): ShutdownOutcome;
    releaseEvidence(): JsonValue;
}
