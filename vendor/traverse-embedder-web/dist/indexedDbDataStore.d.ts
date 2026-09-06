import type { JsonValue } from "./types.js";
export type DataClassification = "public" | "private";
export interface StateRecord {
    readonly key: string;
    readonly value: JsonValue;
    readonly lamport_clock: number;
    readonly writer_id: string;
}
export type IndexedDbDataStoreErrorCode = "invalid_key" | "integrity_check_failed" | "key_provider_required" | "store_locked" | "locking_unsupported" | "quota_exceeded" | "persistence_unavailable" | "backend_failed" | "unsupported";
export type IndexedDbDataStoreOperation = "open" | "read" | "write" | "delete" | "prune" | "backup" | "restore";
/** A stable, secret-free browser DataStore failure (Spec 085 FR-005/FR-007). */
export declare class IndexedDbDataStoreError extends Error {
    readonly code: IndexedDbDataStoreErrorCode;
    readonly operation: IndexedDbDataStoreOperation;
    readonly reason: string;
    constructor(code: IndexedDbDataStoreErrorCode, operation: IndexedDbDataStoreOperation, reason: string);
}
export interface IndexedDbDataStoreConfig {
    /**
     * Host-selected, origin-scoped IndexedDB name. Traverse never derives or
     * supplies a global default name.
     */
    readonly databaseName: string;
    /** Fixed classification for this store. Private operations fail closed. */
    readonly classification: DataClassification;
    /** Browser globals may be injected by a conformance harness. */
    readonly indexedDB?: IDBFactory | null;
    /** Browser Web Locks may be injected by a conformance harness. */
    readonly locks?: WebLockManager | null;
}
interface WebLock {
    readonly name: string;
    readonly mode: "exclusive" | "shared";
}
interface WebLockManager {
    request<T>(name: string, options: {
        readonly mode: "exclusive";
        readonly ifAvailable: true;
    }, callback: (lock: WebLock | null) => Promise<T>): Promise<T>;
}
/**
 * Host-owned IndexedDB implementation of the DataStore public-record port.
 *
 * Opening holds one origin-scoped exclusive Web Lock until `close()`. The
 * adapter exposes no fallback lock and never persists private plaintext.
 */
export declare class IndexedDbDataStore {
    readonly databaseName: string;
    readonly classification: DataClassification;
    private readonly database;
    private releaseLock;
    private lockRequest;
    private closed;
    private constructor();
    static open(config: IndexedDbDataStoreConfig): Promise<IndexedDbDataStore>;
    read(key: string): Promise<StateRecord | null>;
    write(record: StateRecord): Promise<void>;
    delete(key: string): Promise<void>;
    prune(): Promise<never>;
    backup(): Promise<never>;
    restore(): Promise<never>;
    close(): void;
    private ensureOpen;
    private request;
}
export {};
