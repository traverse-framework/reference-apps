/**
 * Production embedder: loads an application-owned bundle and executes
 * bundled WASM capabilities directly in the browser's native WebAssembly
 * host — no `traverse-cli serve`, no server round trip, no nested WASM
 * engine (spec 068 FR-002).
 *
 * Where the native Rust `traverse-embedder` crate embeds Wasmtime to run
 * bundled capability artifacts, the browser *is already* a WebAssembly
 * host: `BundleEmbedder` compiles each bundled capability module with
 * `WebAssembly.compile` once at `init`, validates its imports against the
 * Traverse Host ABI whitelist (`hostAbi.ts`), and instantiates + invokes it
 * synchronously per `submit` through a minimal WASI `preview1` shim
 * (`wasi.ts`) that pipes JSON stdin/stdout exactly like the native
 * `WasmExecutor`.
 *
 * Workflow execution supports linear, `direct`-triggered pipelines only
 * (the shape used by every bundled example workflow today: `analyze` ->
 * `recommend`, single-node `process`). Event-driven / conditional workflow
 * edges (specs 052/053) are out of scope for this package slice and are
 * rejected deterministically at `init` rather than silently mis-executed.
 */
import { EmbedderCore } from "./core.js";
import { BundleRejectedError, asRecord, optionalString, requiredString, validateBundleCompatibility, verifyArtifactDigest, SHA256_DIGEST_PATTERN, } from "./bundleValidation.js";
import { findUnauthorizedImport } from "./hostAbi.js";
import { WasiExit, WasiPipes, createWasiPreview1Imports } from "./wasi.js";
import { embedderError, runtimeStoppedError } from "./types.js";
function loadFailure(message) {
    return new BundleRejectedError(embedderError("bundle_load_failed", message));
}
/** Copies `bytes` into a fresh, non-shared `ArrayBuffer` for WebAssembly APIs. */
function toArrayBuffer(bytes) {
    const copy = new Uint8Array(bytes.byteLength);
    copy.set(bytes);
    return copy.buffer;
}
function stringArray(value, context) {
    if (value === undefined) {
        return [];
    }
    if (!Array.isArray(value)) {
        throw loadFailure(`${context} must be an array`);
    }
    return value.map((entry, index) => {
        if (typeof entry !== "string") {
            throw loadFailure(`${context}[${index}] must be a string`);
        }
        return entry;
    });
}
function initialWorkflowState(input) {
    const record = asRecord(input);
    return record !== null ? { ...record } : { input };
}
function buildNodeInput(state, keys) {
    const input = {};
    for (const key of keys) {
        const value = state[key];
        if (value !== undefined) {
            input[key] = value;
        }
    }
    return input;
}
function applyNodeOutput(state, node, output) {
    const record = asRecord(output);
    if (record === null) {
        return;
    }
    for (const key of node.toWorkflowState) {
        const value = record[key];
        if (value !== undefined) {
            state[key] = value;
        }
    }
    if (node.publishToStateAs !== null) {
        state[node.publishToStateAs] = output;
    }
}
function projectWorkflowOutput(state, projection) {
    if (projection.length === 0) {
        return { ...state };
    }
    const projected = {};
    for (const key of projection) {
        const value = state[key];
        if (value !== undefined) {
            projected[key] = value;
        }
    }
    return projected;
}
export class BundleEmbedder {
    core;
    wasmTargets;
    workflowTargets;
    wasmComponentEvidence;
    constructor(core, wasmTargets, workflowTargets, wasmComponentEvidence) {
        this.core = core;
        this.wasmTargets = wasmTargets;
        this.workflowTargets = workflowTargets;
        this.wasmComponentEvidence = wasmComponentEvidence;
    }
    /**
     * `runtime.init`: load, digest-verify, host-ABI-validate, and compile the
     * application bundle. Rejects deterministically with a `BundleRejectedError`
     * and never falls back to a sidecar (spec 068 NFR-001).
     */
    static async init(config) {
        const { manifestPath, loader } = config;
        let manifestText;
        try {
            manifestText = await loader.loadText(manifestPath);
        }
        catch (error) {
            throw loadFailure(`failed to load application bundle manifest: ${String(error)}`);
        }
        const summary = validateBundleCompatibility(manifestText);
        const wasmTargets = new Map();
        const compatibleTargets = new Map();
        const wasmComponentEvidence = [];
        for (const component of summary.components) {
            const componentManifestPath = loader.resolve(manifestPath, component.manifestPath);
            let componentManifestText;
            try {
                componentManifestText = await loader.loadText(componentManifestPath);
            }
            catch (error) {
                throw loadFailure(`failed to load component manifest '${componentManifestPath}': ${String(error)}`);
            }
            let parsed;
            try {
                parsed = JSON.parse(componentManifestText);
            }
            catch (error) {
                throw loadFailure(`component manifest '${componentManifestPath}' is not valid JSON: ${String(error)}`);
            }
            const record = asRecord(parsed);
            if (record === null) {
                throw loadFailure(`component manifest '${componentManifestPath}' must be a JSON object`);
            }
            const context = `component manifest '${componentManifestPath}'`;
            const capabilityId = requiredString(record, "capability_id", context);
            const capabilityVersion = requiredString(record, "capability_version", context);
            const executionMode = optionalString(record, "execution_mode") ?? "wasm";
            if (executionMode === "compatible") {
                const platforms = stringArray(record["platforms"], `${context} platforms`);
                if (platforms.length === 0) {
                    throw loadFailure(`${context} declares execution_mode 'compatible' but no platforms`);
                }
                compatibleTargets.set(capabilityId, platforms);
                continue;
            }
            if (executionMode !== "wasm") {
                throw loadFailure(`${context} declares unsupported execution_mode '${executionMode}'`);
            }
            const wasmDigest = requiredString(record, "wasm_digest", context);
            if (!SHA256_DIGEST_PATTERN.test(wasmDigest)) {
                throw loadFailure(`${context} declares invalid wasm_digest metadata '${wasmDigest}'`);
            }
            if (wasmDigest.toLowerCase() !== component.digest.toLowerCase()) {
                throw loadFailure(`${context} wasm_digest does not match the app manifest's declared component digest`);
            }
            const wasmBinaryPath = requiredString(record, "wasm_binary_path", context);
            const wasmPath = loader.resolve(componentManifestPath, wasmBinaryPath);
            let wasmBytes;
            try {
                wasmBytes = await loader.loadBytes(wasmPath);
            }
            catch (error) {
                throw loadFailure(`failed to load WASM artifact '${wasmPath}': ${String(error)}`);
            }
            await verifyArtifactDigest(wasmBytes, wasmDigest, `component '${capabilityId}' artifact`);
            let module;
            try {
                module = await WebAssembly.compile(toArrayBuffer(wasmBytes));
            }
            catch (error) {
                throw loadFailure(`component '${capabilityId}' WASM artifact failed to compile: ${String(error)}`);
            }
            const unauthorized = findUnauthorizedImport(module);
            if (unauthorized !== null) {
                throw loadFailure(`component '${capabilityId}' imports unauthorized host function ` +
                    `'${unauthorized.module}.${unauthorized.name}'; Traverse Host ABI 1.0.0 permits ` +
                    "only the whitelisted stdio and traverse_host imports");
            }
            wasmTargets.set(capabilityId, { capabilityVersion, digest: wasmDigest, module });
            wasmComponentEvidence.push({
                component_id: component.componentId,
                capability_id: capabilityId,
                wasm_digest: wasmDigest,
            });
        }
        const workflowTargets = new Map();
        for (const workflowRef of summary.workflows) {
            const workflowPath = loader.resolve(manifestPath, workflowRef.path);
            let workflowText;
            try {
                workflowText = await loader.loadText(workflowPath);
            }
            catch (error) {
                throw loadFailure(`failed to load workflow definition '${workflowPath}': ${String(error)}`);
            }
            let parsed;
            try {
                parsed = JSON.parse(workflowText);
            }
            catch (error) {
                throw loadFailure(`workflow definition '${workflowPath}' is not valid JSON: ${String(error)}`);
            }
            const record = asRecord(parsed);
            if (record === null) {
                throw loadFailure(`workflow definition '${workflowPath}' must be a JSON object`);
            }
            const context = `workflow definition '${workflowPath}'`;
            const startNode = requiredString(record, "start_node", context);
            const outputProjection = stringArray(record["output_projection"], `${context} output_projection`);
            const nodesValue = record["nodes"];
            if (!Array.isArray(nodesValue)) {
                throw loadFailure(`${context} requires a 'nodes' array`);
            }
            const nodes = new Map();
            for (const [index, entry] of nodesValue.entries()) {
                const node = asRecord(entry);
                if (node === null) {
                    throw loadFailure(`${context} nodes[${index}] must be a JSON object`);
                }
                const nodeContext = `${context} nodes[${index}]`;
                const nodeId = requiredString(node, "node_id", nodeContext);
                const input = asRecord(node["input"]);
                const output = asRecord(node["output"]);
                nodes.set(nodeId, {
                    nodeId,
                    capabilityId: requiredString(node, "capability_id", nodeContext),
                    capabilityVersion: requiredString(node, "capability_version", nodeContext),
                    fromWorkflowInput: stringArray(input?.["from_workflow_input"], `${nodeContext}.input.from_workflow_input`),
                    toWorkflowState: stringArray(output?.["to_workflow_state"], `${nodeContext}.output.to_workflow_state`),
                    publishToStateAs: output !== null ? optionalString(output, "publish_to_state_as") : null,
                });
            }
            const edgesValue = record["edges"];
            const nextByFrom = new Map();
            if (Array.isArray(edgesValue)) {
                for (const [index, entry] of edgesValue.entries()) {
                    const edge = asRecord(entry);
                    if (edge === null) {
                        throw loadFailure(`${context} edges[${index}] must be a JSON object`);
                    }
                    const edgeContext = `${context} edges[${index}]`;
                    const trigger = optionalString(edge, "trigger") ?? "direct";
                    if (trigger !== "direct") {
                        throw loadFailure(`${edgeContext} uses trigger '${trigger}'; this package version supports only ` +
                            "'direct'-triggered linear pipelines");
                    }
                    const from = requiredString(edge, "from", edgeContext);
                    const to = requiredString(edge, "to", edgeContext);
                    if (nextByFrom.has(from)) {
                        throw loadFailure(`${edgeContext}: node '${from}' already has an outgoing direct edge; ` +
                            "branching pipelines are not supported by this package version");
                    }
                    nextByFrom.set(from, to);
                }
            }
            workflowTargets.set(workflowRef.workflowId, {
                version: workflowRef.workflowVersion,
                nodes,
                nextByFrom,
                startNode,
                outputProjection,
            });
        }
        const core = new EmbedderCore(config.workspaceId ?? "local-default", summary.appId, summary.appVersion, config.platform ?? "web", compatibleTargets);
        return new BundleEmbedder(core, wasmTargets, workflowTargets, wasmComponentEvidence);
    }
    submit(targetId, input) {
        if (this.core.stopped) {
            return this.core.rejectedSubmit(targetId, runtimeStoppedError());
        }
        if (this.workflowTargets.has(targetId)) {
            return this.submitWorkflow(targetId, input);
        }
        if (this.wasmTargets.has(targetId)) {
            return this.submitCapability(targetId, input);
        }
        if (this.core.compatibleTargets.has(targetId)) {
            return this.core.rejectedSubmit(targetId, embedderError("compatible_lifecycle_required", `capability '${targetId}' is a compatible-mode capability; use compatible.start/stop/kill`));
        }
        return this.core.rejectedSubmit(targetId, embedderError("target_not_found", `'${targetId}' is neither a bundled workflow nor a bundled capability`));
    }
    submitCapability(targetId, input) {
        const target = this.wasmTargets.get(targetId);
        if (target === undefined) {
            return this.core.rejectedSubmit(targetId, embedderError("target_not_found", `'${targetId}' is not a bundled capability`));
        }
        const sessionId = this.core.nextSessionId();
        const requestId = this.core.nextRequestId();
        const executionId = `exec_${requestId}`;
        this.core.emit("capability_invoked", sessionId, {
            execution_id: executionId,
            capability_id: targetId,
            capability_version: target.capabilityVersion,
        });
        const result = executeWasmModule(target, input);
        if (result.ok) {
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
    submitWorkflow(targetId, input) {
        const workflow = this.workflowTargets.get(targetId);
        if (workflow === undefined) {
            return this.core.rejectedSubmit(targetId, embedderError("target_not_found", `'${targetId}' is not a bundled workflow`));
        }
        const sessionId = this.core.nextSessionId();
        const requestId = this.core.nextRequestId();
        const state = initialWorkflowState(input);
        const steps = [];
        let failure = null;
        let stepIndex = 0;
        let currentNodeId = workflow.startNode;
        while (currentNodeId !== undefined) {
            const node = workflow.nodes.get(currentNodeId);
            if (node === undefined) {
                failure = {
                    code: "execution_failed",
                    message: `workflow node '${currentNodeId}' could not be resolved during traversal`,
                };
                break;
            }
            const target = this.wasmTargets.get(node.capabilityId);
            if (target === undefined) {
                steps.push({
                    stepIndex,
                    nodeId: node.nodeId,
                    capabilityId: node.capabilityId,
                    capabilityVersion: node.capabilityVersion,
                    status: "failed",
                });
                failure = {
                    code: "capability_not_found",
                    message: `capability '${node.capabilityId}' is not a bundled WASM capability`,
                };
                break;
            }
            const nodeInput = buildNodeInput(state, node.fromWorkflowInput);
            const result = executeWasmModule(target, nodeInput);
            if (!result.ok) {
                steps.push({
                    stepIndex,
                    nodeId: node.nodeId,
                    capabilityId: node.capabilityId,
                    capabilityVersion: node.capabilityVersion,
                    status: "failed",
                });
                failure = { code: result.code, message: result.message };
                break;
            }
            steps.push({
                stepIndex,
                nodeId: node.nodeId,
                capabilityId: node.capabilityId,
                capabilityVersion: node.capabilityVersion,
                status: "completed",
            });
            applyNodeOutput(state, node, result.output);
            stepIndex += 1;
            currentNodeId = workflow.nextByFrom.get(node.nodeId);
        }
        for (const step of steps) {
            this.core.emit("capability_invoked", sessionId, {
                request_id: requestId,
                workflow_id: targetId,
                workflow_version: workflow.version,
                step_index: step.stepIndex,
                node_id: step.nodeId,
                capability_id: step.capabilityId,
                capability_version: step.capabilityVersion,
                status: step.status,
            });
        }
        if (failure === null) {
            this.core.emit("capability_result", sessionId, {
                request_id: requestId,
                workflow_id: targetId,
                workflow_version: workflow.version,
                status: "completed",
                output: projectWorkflowOutput(state, workflow.outputProjection),
            });
        }
        else {
            this.core.emit("error", sessionId, {
                request_id: requestId,
                workflow_id: targetId,
                workflow_version: workflow.version,
                status: "error",
                error: { code: failure.code, message: failure.message, details: {} },
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
        return this.core.evidence("browser-webassembly", [...this.wasmComponentEvidence]);
    }
}
/**
 * Instantiates and invokes one bundled WASM capability module synchronously
 * against an already-compiled, host-ABI-validated `WebAssembly.Module`,
 * piping `input` as WASI stdin JSON and parsing WASI stdout as the output
 * JSON — the same contract as the native `WasmExecutor` (spec 057).
 */
function executeWasmModule(target, input) {
    const inputBytes = new TextEncoder().encode(JSON.stringify(input));
    const pipes = new WasiPipes(inputBytes);
    const memoryRef = { memory: null };
    const importObject = {
        wasi_snapshot_preview1: createWasiPreview1Imports(pipes, memoryRef),
    };
    let instance;
    try {
        instance = new WebAssembly.Instance(target.module, importObject);
    }
    catch (error) {
        return {
            ok: false,
            output: null,
            code: "constraint_violated",
            message: `module instantiation failed: ${String(error)}`,
        };
    }
    const exportedMemory = instance.exports["memory"];
    memoryRef.memory = exportedMemory instanceof WebAssembly.Memory ? exportedMemory : null;
    const entry = instance.exports["_start"] ?? instance.exports[""];
    if (typeof entry !== "function") {
        return {
            ok: false,
            output: null,
            code: "constraint_violated",
            message: "module has no WASI command entry point ('_start')",
        };
    }
    let trapped = null;
    try {
        entry();
    }
    catch (error) {
        if (error instanceof WasiExit) {
            if (error.code !== 0) {
                trapped = { code: "execution_failed", message: `module exited with code ${error.code}` };
            }
        }
        else {
            trapped = { code: "execution_failed", message: `module trapped: ${String(error)}` };
        }
    }
    if (trapped !== null) {
        return { ok: false, output: null, ...trapped };
    }
    const rawOutput = pipes.stdoutBytes();
    const rawText = new TextDecoder().decode(rawOutput);
    try {
        const output = JSON.parse(rawText);
        return { ok: true, output, code: "", message: "" };
    }
    catch (error) {
        return {
            ok: false,
            output: null,
            code: "output_deserialization_failed",
            message: `stdout is not valid JSON: ${String(error)} — raw: ${rawText}`,
        };
    }
}
