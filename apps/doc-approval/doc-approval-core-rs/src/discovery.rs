use serde::Deserialize;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ServerInfo {
    pub base_url: String,
    pub workspace_default: String,
}

#[derive(Debug, Deserialize)]
struct ServerJson {
    base_url: String,
    #[serde(default = "default_workspace")]
    workspace_default: String,
}

fn default_workspace() -> String {
    "local-default".to_string()
}

pub struct ServerDiscovery;

impl ServerDiscovery {
    pub fn from_file(path: impl AsRef<Path>) -> Option<ServerInfo> {
        let data = fs::read_to_string(path).ok()?;
        let parsed: ServerJson = serde_json::from_str(&data).ok()?;
        Some(ServerInfo {
            base_url: parsed.base_url,
            workspace_default: parsed.workspace_default,
        })
    }

    /// Walk parents from `start` looking for `.traverse/server.json`.
    pub fn discover(start: impl AsRef<Path>) -> Option<ServerInfo> {
        let mut current = start.as_ref().to_path_buf();
        for _ in 0..8 {
            let candidate = current.join(".traverse").join("server.json");
            if let Some(info) = Self::from_file(&candidate) {
                return Some(info);
            }
            if !current.pop() {
                break;
            }
        }
        None
    }

    pub fn discover_cwd() -> Option<ServerInfo> {
        let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
        Self::discover(cwd)
    }
}
