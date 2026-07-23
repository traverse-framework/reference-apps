import type { CompatibleLifecycleOutcome, CompatibleStartOutcome, EmbeddedTraceApiError, EmbeddedTraceDetail, EmbeddedTraceOutcome, EmbeddedTracePage, EmbeddedTracePhase, EmbeddedTracePlacement, EmbeddedTraceSelectedTarget, EmbedderError, EmbedderEvent, EventCallback, JsonValue, SubmitOutcome } from "./types.js";
export interface EmbeddedTraceRecordInput {
    readonly executionId: string;
    readonly targetId: string;
    readonly outcome: EmbeddedTraceOutcome;
    readonly phases: readonly EmbeddedTracePhase[];
    readonly selectedTarget: EmbeddedTraceSelectedTarget | null;
    readonly placement: EmbeddedTracePlacement | null;
    readonly failureCode: string | null;
    readonly stateMachineValid: boolean | null;
}
export declare class EmbedderCore {
    readonly workspaceId: string;
    readonly appId: string;
    readonly appVersion: string;
    readonly platform: string;
    readonly compatibleTargets: Map<string, readonly string[]>;
    private readonly instances;
    private readonly subscribers;
    private readonly history;
    private nextEvent;
    private nextSession;
    private nextRequest;
    private nextInstance;
    private readonly traceSession;
    private nextTrace;
    private readonly traces;
    stopped: boolean;
    constructor(workspaceId: string, appId: string, appVersion: string, platform: string, compatibleTargets: Map<string, readonly string[]>);
    nextSessionId(): string;
    nextRequestId(): string;
    recordTrace(input: EmbeddedTraceRecordInput): void;
    traceList(requestedVersion: string, pageSize: number, cursor?: string | null): EmbeddedTracePage | EmbeddedTraceApiError;
    traceGet(requestedVersion: string, traceId: string): EmbeddedTraceDetail | EmbeddedTraceApiError;
    private traceApiAvailability;
    private newestTraces;
    private cursorFor;
    private cursorStart;
    private nextInstanceId;
    emit(eventType: EmbedderEvent["event_type"], sessionId: string | null, data: JsonValue): void;
    subscribe(callback: EventCallback): void;
    emitErrorEvent(sessionId: string | null, error: EmbedderError, data: {
        [key: string]: JsonValue;
    }): void;
    rejectedSubmit(targetId: string, error: EmbedderError): SubmitOutcome;
    startCompatible(capabilityId: string, input: JsonValue): CompatibleStartOutcome;
    transitionCompatible(capabilityId: string, instanceId: string | null, targetState: "stopped" | "killed"): CompatibleLifecycleOutcome;
    private setInstanceState;
    shutdown(): {
        killedInstances: number;
    };
    evidence(runtimeImplementation: string, wasmComponents: JsonValue): JsonValue;
}
