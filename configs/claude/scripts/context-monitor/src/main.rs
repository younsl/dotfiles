mod color;
mod context;
mod input;
mod level;
mod metrics;

use color::Color;
use context::ContextInfo;
use input::InputData;
use std::io::{self, Read};
use std::path::PathBuf;
use std::process::Command;
use std::{env, fs};

fn main() {
    if let Err(e) = run() {
        let cwd = env::current_dir()
            .ok()
            .and_then(|p| p.file_name().map(|n| n.to_string_lossy().to_string()))
            .unwrap_or_else(|| "unknown".to_string());

        let msg = format!("{e}");
        let truncated = if msg.len() > 20 { &msg[..20] } else { &msg };
        println!(
            "{} {} {}",
            Color::Blue.paint("[Claude]"),
            Color::BrightYellow.paint(&cwd),
            Color::Red.paint(&format!("[Error: {truncated}]")),
        );
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    let data: InputData = serde_json::from_str(&input)?;

    let model_name = data
        .model
        .as_ref()
        .and_then(|m| m.display_name.as_deref())
        .unwrap_or("Claude");

    let effort = read_effort();

    let ctx = resolve_context(&data);

    let model_color = ctx
        .as_ref()
        .map(|c| c.level().model_color())
        .unwrap_or(Color::Blue);

    let context_display = match &ctx {
        Some(info) => info.display(),
        None => context::unknown_display(),
    };

    let directory = format_directory(&data);
    let branch = git_branch(&data);

    let session_metrics = data
        .cost
        .as_ref()
        .map(metrics::format_session_metrics)
        .unwrap_or_default();

    let branch_display = branch
        .map(|b| format!(" {}", Color::Green.paint(&format!("on {b}"))))
        .unwrap_or_default();

    println!(
        "{} {}{branch_display} {context_display}{session_metrics}",
        Color::Bold.paint(&model_color.paint(&format!("{model_name} {effort}"))),
        Color::BrightYellow.paint(&directory),
    );

    Ok(())
}

fn resolve_context(data: &InputData) -> Option<ContextInfo> {
    if let Some(ref ctx) = data.context_window {
        Some(ContextInfo::from_context_window(
            ctx.used_percentage.unwrap_or(0.0),
        ))
    } else {
        data.transcript_path
            .as_deref()
            .and_then(ContextInfo::from_transcript)
    }
}

fn format_directory(data: &InputData) -> String {
    let ws = match &data.workspace {
        Some(ws) => ws,
        None => return "unknown".to_string(),
    };

    let current = ws.current_dir.as_deref().unwrap_or("");
    let project = ws.project_dir.as_deref().unwrap_or("");

    match (current, project) {
        (c, p) if !c.is_empty() && !p.is_empty() => {
            if c.starts_with(p) {
                let rel = c[p.len()..].trim_start_matches('/');
                if rel.is_empty() {
                    basename(p)
                } else {
                    rel.to_string()
                }
            } else {
                basename(c)
            }
        }
        (_, p) if !p.is_empty() => basename(p),
        (c, _) if !c.is_empty() => basename(c),
        _ => "unknown".to_string(),
    }
}

fn basename(path: &str) -> String {
    std::path::Path::new(path)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown")
        .to_string()
}

fn git_branch(data: &InputData) -> Option<String> {
    let dir = data
        .workspace
        .as_ref()
        .and_then(|ws| ws.current_dir.as_deref().or(ws.project_dir.as_deref()));

    let output = Command::new("git")
        .args(["rev-parse", "--abbrev-ref", "HEAD"])
        .current_dir(dir.unwrap_or("."))
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    let branch = String::from_utf8(output.stdout).ok()?.trim().to_string();
    if branch.is_empty() {
        None
    } else {
        Some(branch)
    }
}

fn read_effort() -> String {
    let path = home_dir().join(".claude/settings.json");
    let content = fs::read_to_string(&path).ok();
    let effort = content
        .as_deref()
        .and_then(|c| serde_json::from_str::<serde_json::Value>(c).ok())
        .and_then(|v| v.get("effortLevel")?.as_str().map(String::from))
        .unwrap_or_else(|| "high".to_string());

    capitalize(&effort)
}

fn capitalize(s: &str) -> String {
    let mut c = s.chars();
    match c.next() {
        None => String::new(),
        Some(first) => first.to_uppercase().to_string() + c.as_str(),
    }
}

fn home_dir() -> PathBuf {
    env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/tmp"))
}
