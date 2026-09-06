/**
 * Host-owned verified registry dependency cache (Spec `080-embedded-registry-cache`).
 *
 * Separates network-capable `prepareRegistryDependency` from offline
 * `resolveRegistryDependencyOffline` used at embedder `init`. The host owns
 * cache storage; Traverse never synthesizes a production path or performs
 * network I/O outside prepare.
 */
/** Stable Spec 080 FR-007 error codes. */
export type RegistryCacheErrorCode = "registry_sync_missing" | "registry_version_not_found" | "registry_dependency_yanked" | "registry_prepare_failed" | "registry_artifact_digest_mismatch" | "registry_cache_entry_missing";
export declare class RegistryCacheError extends Error {
    readonly code: RegistryCacheErrorCode;
    constructor(code: RegistryCacheErrorCode, message: string);
}
/** Host-owned byte store for verified cache entries. */
export interface RegistryCacheStore {
    get(key: string): Promise<Uint8Array | undefined> | Uint8Array | undefined;
    set(key: string, bytes: Uint8Array): Promise<void> | void;
    delete(key: string): Promise<void> | void;
    keys(): Promise<readonly string[]> | readonly string[];
}
/** In-memory host cache store for tests and simple hosts. */
export declare class MemoryRegistryCacheStore implements RegistryCacheStore {
    private readonly entries;
    get(key: string): Uint8Array | undefined;
    set(key: string, bytes: Uint8Array): void;
    delete(key: string): void;
    keys(): readonly string[];
}
export interface RegistryReference {
    readonly namespace: string;
    readonly id: string;
    readonly versionRange: string;
}
export interface PublicRegistryCapabilityRecord {
    readonly namespace: string;
    readonly id: string;
    readonly version: string;
    readonly digest: string;
    readonly artifactUrl: string;
    readonly contractDigest: string;
    readonly contractUrl: string;
    readonly deprecated: boolean;
}
export interface SyncedPublicRegistryState {
    readonly releaseTag: string;
    readonly capabilities: readonly PublicRegistryCapabilityRecord[];
}
export interface RegistryArtifactFetcher {
    fetch(url: string): Promise<Uint8Array> | Uint8Array;
}
export interface RegistryPrepareEvidence {
    readonly namespace: string;
    readonly id: string;
    readonly selectedVersion: string;
    readonly versionRange: string;
    readonly sourceRelease: string;
    readonly indexDigest: string;
    readonly artifactDigest: string;
    readonly verifiedAt: number;
    readonly outcome: "prepared" | "resolved";
}
export interface VerifiedRegistryDependency {
    readonly wasmBytes: Uint8Array;
    readonly contractBytes: Uint8Array;
    readonly wasmDigest: string;
    readonly evidence: RegistryPrepareEvidence;
}
/**
 * Prepare one `registry_ref` into a host-owned verified cache.
 * Only this function may call the fetcher.
 */
export declare function prepareRegistryDependency(store: RegistryCacheStore, snapshot: SyncedPublicRegistryState, reference: RegistryReference, fetcher: RegistryArtifactFetcher): Promise<RegistryPrepareEvidence>;
/** Resolve a previously prepared `registry_ref` offline. */
export declare function resolveRegistryDependencyOffline(store: RegistryCacheStore, reference: RegistryReference): Promise<VerifiedRegistryDependency>;
/** Remove one verified artifact entry by digest. */
export declare function evictRegistryCacheEntry(store: RegistryCacheStore, artifactDigest: string): Promise<void>;
/** Clear every verified entry in the host store. */
export declare function evictAllRegistryCacheEntries(store: RegistryCacheStore): Promise<void>;
