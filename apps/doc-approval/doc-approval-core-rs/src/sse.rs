use futures_util::{stream, StreamExt};
use futures_util::stream::BoxStream;
use reqwest::Client;

use crate::client::{DocApprovalClient, DocApprovalClientError};
use crate::state::StateEvent;

pub async fn subscribe_events(
    http: &Client,
    base_url: &str,
    workspace_id: &str,
    app_id: &str,
) -> Result<BoxStream<'static, Result<StateEvent, DocApprovalClientError>>, DocApprovalClientError>
{
    let url = DocApprovalClient::app_events_url(base_url, workspace_id, app_id);
    let response = http
        .get(&url)
        .header("Accept", "text/event-stream")
        .send()
        .await
        .map_err(|e| DocApprovalClientError::Request(e.to_string()))?;
    if !(200..300).contains(&response.status().as_u16()) {
        return Err(DocApprovalClientError::Http(response.status().as_u16()));
    }

    let byte_stream = response.bytes_stream();
    let event_stream = stream::unfold(
        SseParser {
            byte_stream,
            buffer: String::new(),
        },
        |mut parser| async move {
            loop {
                if let Some(event) = parser.pop_event() {
                    return Some((Ok(event), parser));
                }
                match parser.byte_stream.next().await {
                    Some(Ok(chunk)) => {
                        parser.buffer.push_str(&String::from_utf8_lossy(&chunk));
                    }
                    Some(Err(err)) => {
                        return Some((
                            Err(DocApprovalClientError::Request(err.to_string())),
                            parser,
                        ));
                    }
                    None => return None,
                }
            }
        },
    );

    Ok(Box::pin(event_stream))
}

struct SseParser<S> {
    byte_stream: S,
    buffer: String,
}

impl<S> SseParser<S> {
    fn pop_event(&mut self) -> Option<StateEvent> {
        let idx = self.buffer.find("\n\n")?;
        let block = self.buffer[..idx].to_string();
        self.buffer = self.buffer[idx + 2..].to_string();
        parse_block(&block)
    }
}

fn parse_block(block: &str) -> Option<StateEvent> {
    let mut event_type = String::from("message");
    let mut data_lines: Vec<String> = Vec::new();
    for line in block.lines() {
        if line.starts_with(':') {
            continue;
        }
        if let Some(rest) = line.strip_prefix("event:") {
            event_type = rest.trim().to_string();
        } else if let Some(rest) = line.strip_prefix("data:") {
            data_lines.push(rest.trim().to_string());
        }
    }
    if data_lines.is_empty() && event_type != "heartbeat" {
        return None;
    }
    let data = data_lines.join("\n");
    StateEvent::from_sse(&event_type, &data)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_capability_result_block() {
        let block = "event: capability_result\ndata: {\"state\":\"results\",\"session_id\":\"s1\",\"execution_id\":\"e1\",\"output\":{\"docType\":\"nda\",\"parties\":[],\"amounts\":[],\"confidence\":0.9,\"recommendation\":\"approve\"}}";
        let event = parse_block(block).expect("event");
        assert_eq!(event.event_type, "capability_result");
        assert_eq!(
            event.output.as_ref().map(|o| o.doc_type.as_str()),
            Some("nda")
        );
    }
}
