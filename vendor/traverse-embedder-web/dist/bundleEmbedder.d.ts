import type { BundleLoader } from "./bundleLoader.js";
import type { CompatibleLifecycleOutcome, CompatibleStartOutcome, EventCallback, JsonValue, ShutdownOutcome, SubmitOutcome, TraverseEmbedderApi } from "./types.js";
/** Configuration for `BundleEmbedder.init` (`runtime.init` input). */
export interface BundleEmbedderConfig {
    /** Path or URL to the application bundle's `app.manifest.json`. */
    readonly manifestPath: string;
    /** Loader used to fetch bundle files (browser: `FetchBundleLoader`). */
    readonly loader: BundleLoader;
    /** Workspace identity recorded on events. Defaults to `local-default`. */
    readonly workspaceId?: string;
    /** Platform identity checked against compatible-capability allowlists. */
    readonly platform?: string;
}
export declare class BundleEmbedder implements TraverseEmbedderApi {
    private readonly core;
    private readonly wasmTargets;
    private readonly workflowTargets;
    private readonly wasmComponentEvidence;
    private constructor();
    /**
     * `runtime.init`: load, digest-verify, host-ABI-validate, and compile the
     * application bundle. Rejects deterministically with a `BundleRejectedError`
     * and never falls back to a sidecar (spec 068 NFR-001).
     */
    static init(config: BundleEmbedderConfig): Promise<BundleEmbedder>;
    submit(targetId: string, input: JsonValue): SubmitOutcome;
    private submitCapability;
    private submitWorkflow;
    subscribe(callback: EventCallback): void;
    startCompatible(capabilityId: string, input: JsonValue): CompatibleStartOutcome;
    stopCompatible(capabilityId: string, instanceId?: string | null): CompatibleLifecycleOutcome;
    killCompatible(capabilityId: string, instanceId?: string | null): CompatibleLifecycleOutcome;
    shutdown(): ShutdownOutcome;
    releaseEvidence(): JsonValue;
}
