use serde::Deserialize;

#[derive(Deserialize, Default)]
pub struct InputData {
    #[serde(default)]
    pub model: Option<ModelInfo>,
    #[serde(default)]
    pub workspace: Option<WorkspaceInfo>,
    #[serde(default)]
    pub cost: Option<CostData>,
    #[serde(default)]
    pub context_window: Option<ContextWindow>,
    #[serde(default)]
    pub transcript_path: Option<String>,
}

#[derive(Deserialize, Default)]
pub struct ModelInfo {
    #[serde(default)]
    pub display_name: Option<String>,
}

#[derive(Deserialize, Default)]
pub struct WorkspaceInfo {
    #[serde(default)]
    pub current_dir: Option<String>,
    #[serde(default)]
    pub project_dir: Option<String>,
}

#[derive(Deserialize, Default)]
pub struct CostData {
    #[serde(default)]
    pub total_cost_usd: Option<f64>,
    #[serde(default)]
    pub total_duration_ms: Option<u64>,
    #[serde(default)]
    pub total_lines_added: Option<i64>,
    #[serde(default)]
    pub total_lines_removed: Option<i64>,
}

#[derive(Deserialize, Default)]
pub struct ContextWindow {
    #[serde(default)]
    pub used_percentage: Option<f64>,
    #[serde(default)]
    #[allow(dead_code)]
    pub total_input_tokens: Option<u64>,
}
