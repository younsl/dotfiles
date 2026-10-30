use serde::{Deserialize, Serialize};

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
    #[serde(default)]
    pub rate_limits: Option<RateLimits>,
}

#[derive(Deserialize, Serialize, Default)]
pub struct RateLimits {
    #[serde(default)]
    pub five_hour: Option<RateLimitWindow>,
    #[serde(default)]
    pub seven_day: Option<RateLimitWindow>,
}

#[derive(Deserialize, Serialize, Default)]
pub struct RateLimitWindow {
    #[serde(default)]
    pub used_percentage: Option<f64>,
    #[serde(default)]
    pub resets_at: Option<i64>,
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deserialize_full_input() {
        let json = r#"{
            "model": {"display_name": "Claude Opus 4.6"},
            "workspace": {"current_dir": "/tmp/a", "project_dir": "/tmp/b"},
            "cost": {"total_cost_usd": 0.5, "total_duration_ms": 1000, "total_lines_added": 10, "total_lines_removed": 5},
            "context_window": {"used_percentage": 42.0, "total_input_tokens": 80000},
            "transcript_path": "/tmp/transcript.jsonl",
            "rate_limits": {"five_hour": {"used_percentage": 22, "resets_at": 1789576800}, "seven_day": {"used_percentage": 44, "resets_at": 1789693200}}
        }"#;
        let data: InputData = serde_json::from_str(json).unwrap();
        assert_eq!(data.model.unwrap().display_name.unwrap(), "Claude Opus 4.6");
        assert_eq!(
            data.workspace.as_ref().unwrap().current_dir.as_deref(),
            Some("/tmp/a")
        );
        assert_eq!(
            data.workspace.as_ref().unwrap().project_dir.as_deref(),
            Some("/tmp/b")
        );
        assert_eq!(data.cost.as_ref().unwrap().total_lines_added, Some(10));
        assert_eq!(data.cost.as_ref().unwrap().total_lines_removed, Some(5));
        assert!(
            (data
                .context_window
                .as_ref()
                .unwrap()
                .used_percentage
                .unwrap()
                - 42.0)
                .abs()
                < f64::EPSILON
        );
        assert_eq!(
            data.transcript_path.as_deref(),
            Some("/tmp/transcript.jsonl")
        );
        let limits = data.rate_limits.unwrap();
        assert_eq!(limits.five_hour.unwrap().used_percentage, Some(22.0));
        assert_eq!(limits.seven_day.unwrap().used_percentage, Some(44.0));
    }

    #[test]
    fn deserialize_empty_object() {
        let data: InputData = serde_json::from_str("{}").unwrap();
        assert!(data.model.is_none());
        assert!(data.workspace.is_none());
        assert!(data.cost.is_none());
        assert!(data.context_window.is_none());
        assert!(data.transcript_path.is_none());
        assert!(data.rate_limits.is_none());
    }

    #[test]
    fn deserialize_partial_model() {
        let json = r#"{"model": {}}"#;
        let data: InputData = serde_json::from_str(json).unwrap();
        assert!(data.model.unwrap().display_name.is_none());
    }

    #[test]
    fn default_input_data() {
        let data = InputData::default();
        assert!(data.model.is_none());
        assert!(data.workspace.is_none());
    }
}
