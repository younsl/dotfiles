use crate::color::Color;
use crate::input::CostData;

pub fn format_session_metrics(cost: &CostData) -> String {
    let mut parts: Vec<String> = Vec::new();

    if let Some(s) = format_cost(cost.total_cost_usd) {
        parts.push(s);
    }
    if let Some(s) = format_duration(cost.total_duration_ms) {
        parts.push(s);
    }
    if let Some(s) = format_lines(cost.total_lines_added, cost.total_lines_removed) {
        parts.push(s);
    }

    if parts.is_empty() {
        String::new()
    } else {
        format!(" {} {}", Color::Gray.paint("|"), parts.join(" "))
    }
}

fn format_cost(cost_usd: Option<f64>) -> Option<String> {
    let usd = cost_usd.filter(|&c| c > 0.0)?;

    let color = match usd {
        c if c >= 0.10 => Color::Red,
        c if c >= 0.05 => Color::Yellow,
        _ => Color::Green,
    };

    let text = if usd < 0.01 {
        format!("{:.0}¢", usd * 100.0)
    } else {
        format!("${usd:.3}")
    };

    Some(color.paint(&text))
}

fn format_duration(duration_ms: Option<u64>) -> Option<String> {
    let ms = duration_ms.filter(|&d| d > 0)?;
    let minutes = ms as f64 / 60_000.0;

    let color = if minutes >= 30.0 {
        Color::Yellow
    } else {
        Color::Green
    };

    let text = if minutes < 1.0 {
        format!("{}s", ms / 1000)
    } else {
        format!("{minutes:.0}m")
    };

    Some(color.paint(&format!("t:{text}")))
}

fn format_lines(added: Option<i64>, removed: Option<i64>) -> Option<String> {
    let a = added.unwrap_or(0);
    let r = removed.unwrap_or(0);

    if a == 0 && r == 0 {
        return None;
    }

    let net = a - r;

    let color = match net {
        n if n > 0 => Color::Green,
        n if n < 0 => Color::Red,
        _ => Color::Yellow,
    };

    let sign = if net >= 0 { "+" } else { "" };
    Some(color.paint(&format!("{sign}{net}L")))
}
