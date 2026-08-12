(function (root, factory) {
  const client = factory();

  if (typeof module === "object" && module.exports) {
    module.exports = client;
  }

  if (root) {
    root.TraverseBrowserConsumer = client;
  }
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  let baseClient = null;

  if (typeof require === "function") {
    try {
      baseClient = require("./src/browser-adapter-client.js");
    } catch {
      baseClient = null;
    }
  }

  if (!baseClient && typeof globalThis !== "undefined" && globalThis.TraverseBrowserAdapterClient) {
    baseClient = globalThis.TraverseBrowserAdapterClient;
  }

  if (!baseClient) {
    throw new Error(
      "Traverse browser consumer requires the approved browser adapter client to be available.",
    );
  }

  /** Spec 001 presentation states for session chrome. */
  const PRESENTATION_STATES = Object.freeze([
    "idle",
    "loading",
    "loaded",
    "blocked",
    "ended",
    "error",
  ]);

  const APPROVED_BROWSER_CONSUMER_SESSION = {
    ...baseClient.APPROVED_BROWSER_DEMO_SESSION,
    title: "Traverse Browser Consumer",
    summary:
      "Traverse's browser-targeted consumer facade for downstream browser-hosted apps like youaskm3.",
  };

  function presentationStateFromPhase(phase) {
    switch (phase) {
      case "idle":
        return "idle";
      case "streaming":
        return "loading";
      case "completed":
        return "loaded";
      case "error":
        return "error";
      default:
        return "loading";
    }
  }

  function createBrowserConsumerState() {
    const state = baseClient.createLiveDemoState();
    return {
      ...state,
      presentationState: presentationStateFromPhase(state.phase),
    };
  }

  function buildBrowserConsumerSubscriptionRequest() {
    return baseClient.buildApprovedSubscriptionRequest();
  }

  function runBrowserConsumerSubscription(options = {}) {
    return baseClient.runLiveBrowserSubscription(options);
  }

  function applyBrowserConsumerMessage(state, message, created) {
    const next = baseClient.applyBrowserSubscriptionMessage(state, message, created);
    return {
      ...next,
      presentationState: presentationStateFromPhase(next.phase),
    };
  }

  function browserConsumerTraceSummary(trace, terminalResult) {
    return baseClient.traceSummary(trace, terminalResult);
  }

  return {
    APPROVED_BROWSER_CONSUMER_SESSION,
    PRESENTATION_STATES,
    applyBrowserConsumerMessage,
    browserConsumerTraceSummary,
    buildBrowserConsumerSubscriptionRequest,
    createBrowserConsumerState,
    presentationStateFromPhase,
    runBrowserConsumerSubscription,
  };
});
