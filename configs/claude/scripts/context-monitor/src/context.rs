use crate::color::Color;
use crate::level::Level;
use regex::Regex;
use serde_json::Value;
use std::fs;
use std::io::{self, BufRead};
use std::path::Path;

pub enum Warning {
    AutoCompact,
    Low,
}

pub struct ContextInfo {
    pub percent: f64,
    pub warning: Option<Warning>,
}

impl ContextInfo {
    pub fn from_context_window(used_percentage: f64) -> Self {
        Self {
            percent: used_percentage,
            warning: None,
        }
    }

    pub fn from_transcript(transcript_path: &str) -> Option<Self> {
        parse_transcript(transcript_path)
    }

    pub fn level(&self) -> Level {
        Level::from_percent(self.percent)
    }

    pub fn display(&self) -> String {
        let level = self.level();
        let icon = level.icon();
        let alert = self.alert_label();

        let suffix = match (icon.is_empty(), alert.is_empty()) {
            (true, true) => String::new(),
            (false, true) => format!(" {icon}"),
            (true, false) => format!(" {alert}"),
            (false, false) => format!(" {icon} {alert}"),
        };

        format!(
            "ctx:{}{:.0}%{}{suffix}",
            level.color(),
            self.percent,
            Color::Reset,
        )
    }

    fn alert_label(&self) -> &'static str {
        match &self.warning {
            Some(Warning::AutoCompact) => "AUTO-COMPACT!",
            Some(Warning::Low) => "LOW!",
            None => match self.level() {
                Level::Critical => "CRIT",
                Level::High => "HIGH",
                _ => "",
            },
        }
    }
}

pub fn unknown_display() -> String {
    "ctx:???".to_string()
}

const TAIL_LINES: usize = 15;
const CONTEXT_LIMIT: f64 = 200_000.0;

fn parse_transcript(transcript_path: &str) -> Option<ContextInfo> {
    let path = Path::new(transcript_path);
    if !path.exists() {
        return None;
    }

    let file = fs::File::open(path).ok()?;
    let lines: Vec<String> = io::BufReader::new(file)
        .lines()
        .filter_map(|l| l.ok())
        .collect();

    let start = lines.len().saturating_sub(TAIL_LINES);
    let recent = &lines[start..];

    let auto_compact_re = Regex::new(r"Context left until auto-compact: (\d+)%").ok()?;
    let low_re = Regex::new(r"Context low \((\d+)% remaining\)").ok()?;

    for line in recent.iter().rev() {
        let data: Value = match serde_json::from_str(line.trim()) {
            Ok(v) => v,
            Err(_) => continue,
        };

        match data.get("type").and_then(|t| t.as_str()) {
            Some("assistant") => {
                if let Some(info) = parse_usage_tokens(&data) {
                    return Some(info);
                }
            }
            Some("system_message") => {
                let content = data.get("content").and_then(|c| c.as_str()).unwrap_or("");
                if let Some(info) = parse_system_warning(content, &auto_compact_re, &low_re) {
                    return Some(info);
                }
            }
            _ => continue,
        }
    }

    None
}

fn parse_usage_tokens(data: &Value) -> Option<ContextInfo> {
    let usage = data.get("message")?.get("usage")?;

    let get = |key| usage.get(key).and_then(|v| v.as_u64()).unwrap_or(0);
    let total =
        get("input_tokens") + get("cache_read_input_tokens") + get("cache_creation_input_tokens");

    if total > 0 {
        let percent = (total as f64 / CONTEXT_LIMIT * 100.0).min(100.0);
        Some(ContextInfo {
            percent,
            warning: None,
        })
    } else {
        None
    }
}

fn parse_system_warning(
    content: &str,
    auto_compact_re: &Regex,
    low_re: &Regex,
) -> Option<ContextInfo> {
    if let Some(caps) = auto_compact_re.captures(content) {
        let left: f64 = caps[1].parse().ok()?;
        return Some(ContextInfo {
            percent: 100.0 - left,
            warning: Some(Warning::AutoCompact),
        });
    }

    if let Some(caps) = low_re.captures(content) {
        let left: f64 = caps[1].parse().ok()?;
        return Some(ContextInfo {
            percent: 100.0 - left,
            warning: Some(Warning::Low),
        });
    }

    None
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn from_context_window_basic() {
        let info = ContextInfo::from_context_window(50.0);
        assert!((info.percent - 50.0).abs() < f64::EPSILON);
        assert!(info.warning.is_none());
    }

    #[test]
    fn level_delegation() {
        let info = ContextInfo::from_context_window(96.0);
        assert!(matches!(info.level(), Level::Critical));
    }

    #[test]
    fn unknown_display_value() {
        assert_eq!(unknown_display(), "ctx:???");
    }

    #[test]
    fn display_normal() {
        let info = ContextInfo::from_context_window(30.0);
        let d = info.display();
        assert!(d.contains("ctx:"));
        assert!(d.contains("30%"));
    }

    #[test]
    fn display_critical_shows_crit() {
        let info = ContextInfo::from_context_window(96.0);
        let d = info.display();
        assert!(d.contains("CRIT"));
        assert!(d.contains("!!"));
    }

    #[test]
    fn display_high_shows_high() {
        let info = ContextInfo::from_context_window(92.0);
        let d = info.display();
        assert!(d.contains("HIGH"));
        assert!(d.contains("!"));
    }

    #[test]
    fn display_warning_shows_star() {
        let info = ContextInfo::from_context_window(80.0);
        let d = info.display();
        assert!(d.contains("*"));
    }

    #[test]
    fn display_auto_compact_warning() {
        let info = ContextInfo {
            percent: 85.0,
            warning: Some(Warning::AutoCompact),
        };
        let d = info.display();
        assert!(d.contains("AUTO-COMPACT!"));
    }

    #[test]
    fn display_low_warning() {
        let info = ContextInfo {
            percent: 88.0,
            warning: Some(Warning::Low),
        };
        let d = info.display();
        assert!(d.contains("LOW!"));
    }

    #[test]
    fn parse_system_warning_auto_compact() {
        let auto_compact_re = Regex::new(r"Context left until auto-compact: (\d+)%").unwrap();
        let low_re = Regex::new(r"Context low \((\d+)% remaining\)").unwrap();

        let content = "Context left until auto-compact: 15%";
        let result = parse_system_warning(content, &auto_compact_re, &low_re);
        assert!(result.is_some());
        let info = result.unwrap();
        assert!((info.percent - 85.0).abs() < f64::EPSILON);
        assert!(matches!(info.warning, Some(Warning::AutoCompact)));
    }

    #[test]
    fn parse_system_warning_low() {
        let auto_compact_re = Regex::new(r"Context left until auto-compact: (\d+)%").unwrap();
        let low_re = Regex::new(r"Context low \((\d+)% remaining\)").unwrap();

        let content = "Context low (20% remaining)";
        let result = parse_system_warning(content, &auto_compact_re, &low_re);
        assert!(result.is_some());
        let info = result.unwrap();
        assert!((info.percent - 80.0).abs() < f64::EPSILON);
        assert!(matches!(info.warning, Some(Warning::Low)));
    }

    #[test]
    fn parse_system_warning_no_match() {
        let auto_compact_re = Regex::new(r"Context left until auto-compact: (\d+)%").unwrap();
        let low_re = Regex::new(r"Context low \((\d+)% remaining\)").unwrap();

        let content = "Some other message";
        assert!(parse_system_warning(content, &auto_compact_re, &low_re).is_none());
    }

    #[test]
    fn parse_usage_tokens_valid() {
        let data: Value = serde_json::json!({
            "message": {
                "usage": {
                    "input_tokens": 50000,
                    "cache_read_input_tokens": 10000,
                    "cache_creation_input_tokens": 5000
                }
            }
        });
        let result = parse_usage_tokens(&data);
        assert!(result.is_some());
        let info = result.unwrap();
        // (50000 + 10000 + 5000) / 200000 * 100 = 32.5%
        assert!((info.percent - 32.5).abs() < 0.1);
    }

    #[test]
    fn parse_usage_tokens_zero() {
        let data: Value = serde_json::json!({
            "message": {
                "usage": {
                    "input_tokens": 0,
                    "cache_read_input_tokens": 0,
                    "cache_creation_input_tokens": 0
                }
            }
        });
        assert!(parse_usage_tokens(&data).is_none());
    }

    #[test]
    fn parse_usage_tokens_no_message() {
        let data: Value = serde_json::json!({});
        assert!(parse_usage_tokens(&data).is_none());
    }

    #[test]
    fn from_transcript_nonexistent_file() {
        assert!(ContextInfo::from_transcript("/tmp/nonexistent_ctx_monitor_test").is_none());
    }

    #[test]
    fn from_transcript_with_assistant_usage() {
        let dir = std::env::temp_dir().join("ctx_monitor_test_transcript");
        let _ = fs::create_dir_all(&dir);
        let path = dir.join("test_assistant.jsonl");

        let mut f = fs::File::create(&path).unwrap();
        writeln!(f, r#"{{"type":"assistant","message":{{"usage":{{"input_tokens":100000,"cache_read_input_tokens":20000,"cache_creation_input_tokens":5000}}}}}}"#).unwrap();
        drop(f);

        let result = ContextInfo::from_transcript(path.to_str().unwrap());
        assert!(result.is_some());
        let info = result.unwrap();
        // (100000+20000+5000)/200000*100 = 62.5%
        assert!((info.percent - 62.5).abs() < 0.1);

        let _ = fs::remove_file(&path);
        let _ = fs::remove_dir(&dir);
    }

    #[test]
    fn from_transcript_with_system_warning() {
        let dir = std::env::temp_dir().join("ctx_monitor_test_transcript2");
        let _ = fs::create_dir_all(&dir);
        let path = dir.join("test_system.jsonl");

        let mut f = fs::File::create(&path).unwrap();
        writeln!(
            f,
            r#"{{"type":"system_message","content":"Context left until auto-compact: 10%"}}"#
        )
        .unwrap();
        drop(f);

        let result = ContextInfo::from_transcript(path.to_str().unwrap());
        assert!(result.is_some());
        let info = result.unwrap();
        assert!((info.percent - 90.0).abs() < f64::EPSILON);
        assert!(matches!(info.warning, Some(Warning::AutoCompact)));

        let _ = fs::remove_file(&path);
        let _ = fs::remove_dir(&dir);
    }

    #[test]
    fn from_transcript_skips_invalid_json() {
        let dir = std::env::temp_dir().join("ctx_monitor_test_transcript3");
        let _ = fs::create_dir_all(&dir);
        let path = dir.join("test_invalid.jsonl");

        let mut f = fs::File::create(&path).unwrap();
        writeln!(f, "not json at all").unwrap();
        writeln!(f, r#"{{"type":"other"}}"#).unwrap();
        drop(f);

        let result = ContextInfo::from_transcript(path.to_str().unwrap());
        assert!(result.is_none());

        let _ = fs::remove_file(&path);
        let _ = fs::remove_dir(&dir);
    }
}
