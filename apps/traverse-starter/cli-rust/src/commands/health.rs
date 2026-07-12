use crate::client::TraverseClient;
use crate::output::print_health;

pub fn execute(base_url: &str, json: bool) -> i32 {
    let runtime = match tokio::runtime::Runtime::new() {
        Ok(rt) => rt,
        Err(err) => {
            eprintln!("runtime failed: {err}");
            return 1;
        }
    };
    let online = runtime.block_on(async {
        let client = TraverseClient::new();
        client.check_health(base_url).await.unwrap_or(false)
    });
    print_health(base_url, online, json);
    if online {
        0
    } else {
        1
    }
}
