use directories::ProjectDirs;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

use crate::{DEFAULT_BASE_URL, DEFAULT_WORKSPACE};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AppSettings {
    pub base_url: String,
    pub workspace: String,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            base_url: DEFAULT_BASE_URL.to_string(),
            workspace: DEFAULT_WORKSPACE.to_string(),
        }
    }
}

pub fn settings_path() -> Option<PathBuf> {
    ProjectDirs::from("com", "traverse-framework", "traverse-starter")
        .map(|dirs| dirs.config_dir().join("settings.json"))
}

pub fn load_settings() -> AppSettings {
    let Some(path) = settings_path() else {
        return AppSettings::default();
    };
    fs::read_to_string(path)
        .ok()
        .and_then(|raw| serde_json::from_str(&raw).ok())
        .unwrap_or_default()
}

pub fn save_settings(settings: &AppSettings) -> std::io::Result<()> {
    let Some(path) = settings_path() else {
        return Ok(());
    };
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(path, serde_json::to_string_pretty(settings).unwrap_or_default())
}
