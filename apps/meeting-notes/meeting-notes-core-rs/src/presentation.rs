//! Spec 001/002 presentation + capability progress (language-equivalent of
//! `packages/event-ui-conformance`).

use serde_json::Value;

/// Canonical UI presentation states (Spec 001).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PresentationState {
    Idle,
    Loading,
    Loaded,
    Blocked,
    Ended,
    Error,
}

impl PresentationState {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Idle => "idle",
            Self::Loading => "loading",
            Self::Loaded => "loaded",
            Self::Blocked => "blocked",
            Self::Ended => "ended",
            Self::Error => "error",
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct PresentationSnapshot {
    pub state: PresentationState,
    pub error_message: Option<String>,
    pub output: Option<Value>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CapabilityPhase {
    Invoked,
    Result,
}

impl CapabilityPhase {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Invoked => "invoked",
            Self::Result => "result",
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct CapabilityProgressStep {
    pub capability_id: String,
    pub phase: CapabilityPhase,
    pub sequence: u64,
    pub status: Option<String>,
    pub output: Option<Value>,
}

/// Minimal embedder event fields required by the mapper.
#[derive(Debug, Clone)]
pub struct EmbedderEventLike {
    pub event_type: String,
    pub sequence: u64,
    pub data: Value,
}

fn as_str_field(data: &Value, key: &str) -> Option<String> {
    data.get(key)?.as_str().map(str::to_string)
}

fn error_message_from_data(data: &Value) -> Option<String> {
    match data.get("error") {
        Some(Value::String(s)) => Some(s.clone()),
        Some(Value::Object(map)) => map
            .get("message")
            .and_then(|m| m.as_str())
            .map(str::to_string),
        _ => None,
    }
}

fn runtime_state_token(data: &Value) -> Option<String> {
    as_str_field(data, "state")
        .or_else(|| as_str_field(data, "status"))
        .or_else(|| as_str_field(data, "runtime_state"))
}

fn is_blocked_payload(data: &Value) -> bool {
    if data.get("blocked").and_then(|v| v.as_bool()) == Some(true)
        || data.get("waiting_for_human").and_then(|v| v.as_bool()) == Some(true)
    {
        return true;
    }
    runtime_state_token(data)
        .map(|token| {
            matches!(
                token.to_lowercase().as_str(),
                "blocked" | "waiting" | "waiting_for_human" | "awaiting_human" | "awaiting_input"
            )
        })
        .unwrap_or(false)
}

fn is_ended_state_payload(data: &Value) -> bool {
    runtime_state_token(data)
        .map(|token| {
            matches!(
                token.to_lowercase().as_str(),
                "cancelled" | "canceled" | "closed" | "ended"
            )
        })
        .unwrap_or(false)
}

fn has_renderable_output(data: &Value) -> bool {
    match data.get("output") {
        None => false,
        Some(Value::Null) => false,
        Some(Value::Object(map)) if map.is_empty() => false,
        Some(_) => true,
    }
}

/// Pure mapper: ordered public embedder events → one presentation snapshot.
pub fn map_presentation_state(events: &[EmbedderEventLike]) -> PresentationSnapshot {
    if events.is_empty() {
        return PresentationSnapshot {
            state: PresentationState::Idle,
            error_message: None,
            output: None,
        };
    }

    let mut state = PresentationState::Idle;
    let mut error_message = None;
    let mut output = None;

    for event in events {
        match event.event_type.as_str() {
            "error" => {
                state = PresentationState::Error;
                error_message =
                    Some(error_message_from_data(&event.data).unwrap_or_else(|| {
                        "execution failed".to_string()
                    }));
            }
            "capability_invoked" => {
                if state != PresentationState::Error {
                    state = PresentationState::Loading;
                }
            }
            "state_changed" => {
                if state == PresentationState::Error {
                    continue;
                }
                if is_blocked_payload(&event.data) {
                    state = PresentationState::Blocked;
                } else if is_ended_state_payload(&event.data) {
                    state = PresentationState::Ended;
                } else if state != PresentationState::Loaded && state != PresentationState::Ended {
                    state = PresentationState::Loading;
                }
            }
            "capability_result" => {
                if state == PresentationState::Error {
                    continue;
                }
                if has_renderable_output(&event.data) {
                    state = PresentationState::Loaded;
                    output = event.data.get("output").cloned();
                } else {
                    state = PresentationState::Ended;
                    output = None;
                }
            }
            _ => {}
        }
    }

    PresentationSnapshot {
        state,
        error_message,
        output,
    }
}

/// Ordered capability progress from `capability_invoked` / `capability_result`.
pub fn map_capability_progress(events: &[EmbedderEventLike]) -> Vec<CapabilityProgressStep> {
    let mut steps = Vec::new();
    for event in events {
        let Some(capability_id) = as_str_field(&event.data, "capability_id") else {
            continue;
        };
        match event.event_type.as_str() {
            "capability_invoked" => steps.push(CapabilityProgressStep {
                capability_id,
                phase: CapabilityPhase::Invoked,
                sequence: event.sequence,
                status: None,
                output: None,
            }),
            "capability_result" => steps.push(CapabilityProgressStep {
                capability_id,
                phase: CapabilityPhase::Result,
                sequence: event.sequence,
                status: as_str_field(&event.data, "status"),
                output: event.data.get("output").cloned(),
            }),
            _ => {}
        }
    }
    steps
}

/// Active capability: last invoked without a later result for that id.
pub fn active_capability_id(events: &[EmbedderEventLike]) -> Option<String> {
    let progress = map_capability_progress(events);
    let mut open: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
    for step in &progress {
        match step.phase {
            CapabilityPhase::Invoked => {
                *open.entry(step.capability_id.clone()).or_insert(0) += 1;
            }
            CapabilityPhase::Result => {
                if let Some(count) = open.get_mut(&step.capability_id) {
                    if *count <= 1 {
                        open.remove(&step.capability_id);
                    } else {
                        *count -= 1;
                    }
                }
            }
        }
    }
    for step in progress.iter().rev() {
        if step.phase == CapabilityPhase::Invoked && open.contains_key(&step.capability_id) {
            return Some(step.capability_id.clone());
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::fs;
    use std::path::PathBuf;

    fn fixtures_dir() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../../fixtures/event-ui-conformance")
    }

    fn load_case(name: &str) -> (PresentationState, Vec<EmbedderEventLike>) {
        let raw = fs::read_to_string(fixtures_dir().join(name)).expect("fixture");
        let value: Value = serde_json::from_str(&raw).expect("json");
        let expected = match value["expected_presentation_state"].as_str().unwrap() {
            "idle" => PresentationState::Idle,
            "loading" => PresentationState::Loading,
            "loaded" => PresentationState::Loaded,
            "blocked" => PresentationState::Blocked,
            "ended" => PresentationState::Ended,
            "error" => PresentationState::Error,
            other => panic!("unknown state {other}"),
        };
        let events = value["events"]
            .as_array()
            .unwrap()
            .iter()
            .map(|event| EmbedderEventLike {
                event_type: event["event_type"].as_str().unwrap().to_string(),
                sequence: event["sequence"].as_u64().unwrap(),
                data: event["data"].clone(),
            })
            .collect();
        (expected, events)
    }

    #[test]
    fn maps_catalog_fixtures() {
        for name in [
            "happy-path.json",
            "error-path.json",
            "blocked-path.json",
            "ended-path.json",
            "multi-capability.json",
            "replay-late-subscriber.json",
        ] {
            let (expected, events) = load_case(name);
            let snap = map_presentation_state(&events);
            assert_eq!(snap.state, expected, "fixture {name}");
        }
    }

    #[test]
    fn multi_capability_progress_order() {
        let (_, events) = load_case("multi-capability.json");
        let progress = map_capability_progress(&events);
        let order: Vec<_> = progress
            .iter()
            .map(|s| (s.capability_id.as_str(), s.phase.as_str()))
            .collect();
        assert_eq!(
            order,
            vec![
                ("fixture.analyze", "invoked"),
                ("fixture.analyze", "result"),
                ("fixture.recommend", "invoked"),
                ("fixture.recommend", "result"),
            ]
        );
        assert!(active_capability_id(&events).is_none());
    }

    #[test]
    fn empty_stream_is_idle() {
        let snap = map_presentation_state(&[]);
        assert_eq!(snap.state, PresentationState::Idle);
        assert_eq!(snap.output, None);
        assert_eq!(snap.error_message, None);
    }

    #[test]
    fn loading_while_invoked() {
        let events = vec![EmbedderEventLike {
            event_type: "capability_invoked".into(),
            sequence: 1,
            data: json!({"capability_id": "fixture.process"}),
        }];
        assert_eq!(
            map_presentation_state(&events).state,
            PresentationState::Loading
        );
        assert_eq!(
            active_capability_id(&events).as_deref(),
            Some("fixture.process")
        );
    }
}
