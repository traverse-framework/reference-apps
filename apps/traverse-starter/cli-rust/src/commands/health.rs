use crate::client::TraverseClient;
use crate::output::print_health;

pub fn execute(base_url: &str, json: bool) -> i32 {
    let client = TraverseClient::new();
    let online = client.check_health(base_url).unwrap_or(false);
    print_health(base_url, online, json);
    if online { 0 } else { 1 }
}
