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
