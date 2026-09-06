/**
 * Host-owned verified registry dependency cache (Spec `080-embedded-registry-cache`).
 *
 * Separates network-capable `prepareRegistryDependency` from offline
 * `resolveRegistryDependencyOffline` used at embedder `init`. The host owns
 * cache storage; Traverse never synthesizes a production path or performs
 * network I/O outside prepare.
 */
import { BundleRejectedError, verifyArtifactDigest } from "./bundleValidation.js";
export class RegistryCacheError extends Error {
    code;
    constructor(code, message) {
        super(message);
        this.name = "RegistryCacheError";
        this.code = code;
    }
}
/** In-memory host cache store for tests and simple hosts. */
export class MemoryRegistryCacheStore {
    entries = new Map();
    get(key) {
        return this.entries.get(key);
    }
    set(key, bytes) {
        this.entries.set(key, bytes);
    }
    delete(key) {
        this.entries.delete(key);
    }
    keys() {
        return [...this.entries.keys()];
    }
}
function textEncoder() {
    return new TextEncoder();
}
function textDecoder() {
    return new TextDecoder();
}
async function sha256Hex(bytes) {
    const copy = new Uint8Array(bytes.byteLength);
    copy.set(bytes);
    const digest = await crypto.subtle.digest("SHA-256", copy);
    return [...new Uint8Array(digest)]
        .map((byte) => byte.toString(16).padStart(2, "0"))
        .join("");
}
async function digestFor(bytes) {
    return `sha256:${await sha256Hex(bytes)}`;
}
function normalizeDigest(digest) {
    if (!digest.startsWith("sha256:")) {
        return undefined;
    }
    const hex = digest.slice("sha256:".length).toLowerCase();
    if (hex.length !== 64 || !/^[0-9a-f]+$/.test(hex)) {
        return undefined;
    }
    return hex;
}
async function refKey(reference) {
    const material = `${reference.namespace}:${reference.id}:${reference.versionRange}`;
    return `refs/${await sha256Hex(textEncoder().encode(material))}.json`;
}
function artifactKey(digestHex) {
    return `sha256/${digestHex}`;
}
function metaKey(digestHex) {
    return `meta/${digestHex}.json`;
}
function compareSemver(left, right) {
    const parse = (value) => value.split(".").map((part) => Number.parseInt(part, 10) || 0);
    const a = parse(left);
    const b = parse(right);
    for (let i = 0; i < Math.max(a.length, b.length); i += 1) {
        const delta = (a[i] ?? 0) - (b[i] ?? 0);
        if (delta !== 0) {
            return delta;
        }
    }
    return 0;
}
function matchesCaretRange(version, range) {
    const caret = range.startsWith("^") ? range.slice(1) : range;
    if (range === "*" || range === "x") {
        return true;
    }
    if (!range.startsWith("^")) {
        return version === range || version.startsWith(`${range}.`);
    }
    const [major = 0, minor = 0] = caret
        .split(".")
        .map((part) => Number.parseInt(part, 10) || 0);
    const [vMajorRaw, vMinorRaw = 0, vPatchRaw = 0] = version
        .split(".")
        .map((part) => Number.parseInt(part, 10) || 0);
    const vMajor = vMajorRaw ?? 0;
    const vMinor = vMinorRaw ?? 0;
    const vPatch = vPatchRaw ?? 0;
    if (vMajor !== major) {
        return false;
    }
    if (major === 0) {
        return vMinor === minor;
    }
    return (compareSemver(version, caret) >= 0 &&
        compareSemver(`${major + 1}.0.0`, version) > 0 &&
        Number.isFinite(vPatch));
}
function selectHighestActive(snapshot, reference) {
    const matching = snapshot.capabilities.filter((record) => record.namespace === reference.namespace &&
        record.id === reference.id &&
        matchesCaretRange(record.version, reference.versionRange));
    const active = matching
        .filter((record) => !record.deprecated)
        .sort((left, right) => compareSemver(right.version, left.version));
    if (active[0]) {
        return active[0];
    }
    if (matching.length === 0) {
        throw new RegistryCacheError("registry_version_not_found", `no synced public registry version for ${reference.namespace}:${reference.id} satisfies ${reference.versionRange}`);
    }
    throw new RegistryCacheError("registry_dependency_yanked", `only yanked public registry versions for ${reference.namespace}:${reference.id} satisfy ${reference.versionRange}`);
}
async function writeVerified(store, digest, bytes) {
    const hex = normalizeDigest(digest);
    if (!hex) {
        throw new RegistryCacheError("registry_artifact_digest_mismatch", "registry digest must be sha256: followed by 64 hex characters");
    }
    try {
        await verifyArtifactDigest(bytes, digest, "registry artifact");
    }
    catch (error) {
        if (error instanceof BundleRejectedError) {
            throw new RegistryCacheError("registry_artifact_digest_mismatch", "registry artifact bytes do not match the published digest");
        }
        throw error;
    }
    const key = artifactKey(hex);
    const existing = await store.get(key);
    if (existing) {
        try {
            await verifyArtifactDigest(existing, digest, "cached registry artifact");
        }
        catch {
            throw new RegistryCacheError("registry_artifact_digest_mismatch", "existing registry cache entry digest mismatch");
        }
        return hex;
    }
    await store.set(key, bytes);
    return hex;
}
/**
 * Prepare one `registry_ref` into a host-owned verified cache.
 * Only this function may call the fetcher.
 */
export async function prepareRegistryDependency(store, snapshot, reference, fetcher) {
    if (snapshot.capabilities.length === 0) {
        throw new RegistryCacheError("registry_sync_missing", "synced registry index snapshot contains no capabilities");
    }
    const record = selectHighestActive(snapshot, reference);
    const indexDigest = await digestFor(textEncoder().encode(JSON.stringify(snapshot)));
    let artifactBytes;
    let contractBytes;
    try {
        artifactBytes = await fetcher.fetch(record.artifactUrl);
        contractBytes = await fetcher.fetch(record.contractUrl);
    }
    catch (error) {
        throw new RegistryCacheError("registry_prepare_failed", `host registry fetch failed: ${error instanceof Error ? error.message : "unknown"}`);
    }
    try {
        await writeVerified(store, record.digest, artifactBytes);
        await writeVerified(store, record.contractDigest, contractBytes);
    }
    catch (error) {
        if (error instanceof RegistryCacheError) {
            throw error;
        }
        throw new RegistryCacheError("registry_artifact_digest_mismatch", "registry artifact bytes do not match the published digest");
    }
    const artifactHex = normalizeDigest(record.digest);
    if (!artifactHex) {
        throw new RegistryCacheError("registry_prepare_failed", "artifact digest must be sha256: followed by 64 hex characters");
    }
    const verifiedAt = Math.floor(Date.now() / 1000);
    const meta = {
        namespace: record.namespace,
        id: record.id,
        selectedVersion: record.version,
        versionRange: reference.versionRange,
        sourceRelease: snapshot.releaseTag,
        indexDigest,
        artifactDigest: record.digest,
        contractDigest: record.contractDigest,
        verifiedAt,
    };
    await store.set(metaKey(artifactHex), textEncoder().encode(JSON.stringify(meta)));
    await store.set(await refKey(reference), textEncoder().encode(JSON.stringify({
        artifactDigest: record.digest,
        contractDigest: record.contractDigest,
    })));
    return {
        namespace: record.namespace,
        id: record.id,
        selectedVersion: record.version,
        versionRange: reference.versionRange,
        sourceRelease: snapshot.releaseTag,
        indexDigest,
        artifactDigest: record.digest,
        verifiedAt,
        outcome: "prepared",
    };
}
/** Resolve a previously prepared `registry_ref` offline. */
export async function resolveRegistryDependencyOffline(store, reference) {
    const pointerBytes = await store.get(await refKey(reference));
    if (!pointerBytes) {
        throw new RegistryCacheError("registry_cache_entry_missing", "verified registry cache entry is missing for registry_ref");
    }
    const pointer = JSON.parse(textDecoder().decode(pointerBytes));
    if (!pointer.artifactDigest || !pointer.contractDigest) {
        throw new RegistryCacheError("registry_cache_entry_missing", "verified registry cache entry is missing for registry_ref");
    }
    const artifactHex = normalizeDigest(pointer.artifactDigest);
    const contractHex = normalizeDigest(pointer.contractDigest);
    if (!artifactHex || !contractHex) {
        throw new RegistryCacheError("registry_cache_entry_missing", "verified registry cache entry is missing for registry_ref");
    }
    const wasmBytes = await store.get(artifactKey(artifactHex));
    const contractBytes = await store.get(artifactKey(contractHex));
    const metaBytes = await store.get(metaKey(artifactHex));
    if (!wasmBytes || !contractBytes || !metaBytes) {
        throw new RegistryCacheError("registry_cache_entry_missing", "verified registry cache entry is missing for registry_ref");
    }
    await verifyArtifactDigest(wasmBytes, pointer.artifactDigest, "cached registry artifact");
    await verifyArtifactDigest(contractBytes, pointer.contractDigest, "cached registry contract");
    const meta = JSON.parse(textDecoder().decode(metaBytes));
    return {
        wasmBytes,
        contractBytes,
        wasmDigest: pointer.artifactDigest,
        evidence: {
            namespace: meta.namespace,
            id: meta.id,
            selectedVersion: meta.selectedVersion,
            versionRange: meta.versionRange,
            sourceRelease: meta.sourceRelease,
            indexDigest: meta.indexDigest,
            artifactDigest: meta.artifactDigest,
            verifiedAt: meta.verifiedAt,
            outcome: "resolved",
        },
    };
}
/** Remove one verified artifact entry by digest. */
export async function evictRegistryCacheEntry(store, artifactDigest) {
    const hex = normalizeDigest(artifactDigest);
    if (!hex) {
        throw new RegistryCacheError("registry_prepare_failed", "artifact digest must be sha256: followed by 64 hex characters");
    }
    await store.delete(artifactKey(hex));
    await store.delete(metaKey(hex));
}
/** Clear every verified entry in the host store. */
export async function evictAllRegistryCacheEntries(store) {
    for (const key of await store.keys()) {
        if (key.startsWith("sha256/") ||
            key.startsWith("meta/") ||
            key.startsWith("refs/")) {
            await store.delete(key);
        }
    }
}
