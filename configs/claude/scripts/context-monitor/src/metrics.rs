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

#[cfg(test)]
mod tests {
    use super::*;

    fn cost(
        usd: Option<f64>,
        ms: Option<u64>,
        added: Option<i64>,
        removed: Option<i64>,
    ) -> CostData {
        CostData {
            total_cost_usd: usd,
            total_duration_ms: ms,
            total_lines_added: added,
            total_lines_removed: removed,
        }
    }

    #[test]
    fn empty_cost_returns_empty() {
        let c = cost(None, None, None, None);
        assert_eq!(format_session_metrics(&c), "");
    }

    #[test]
    fn zero_values_returns_empty() {
        let c = cost(Some(0.0), Some(0), Some(0), Some(0));
        assert_eq!(format_session_metrics(&c), "");
    }

    #[test]
    fn format_cost_sub_cent() {
        let result = format_cost(Some(0.009));
        assert!(result.is_some());
        let s = result.unwrap();
        assert!(s.contains("¢"), "Got: {s}");
    }

    #[test]
    fn format_cost_dollars() {
        let result = format_cost(Some(0.042));
        assert!(result.is_some());
        let s = result.unwrap();
        assert!(s.contains("$0.042"), "Got: {s}");
    }

    #[test]
    fn format_cost_high() {
        let result = format_cost(Some(0.15));
        assert!(result.is_some());
        // Should use Red color
        let s = result.unwrap();
        assert!(s.contains("\x1b[31m"));
    }

    #[test]
    fn format_cost_medium() {
        let result = format_cost(Some(0.07));
        assert!(result.is_some());
        // Should use Yellow color
        let s = result.unwrap();
        assert!(s.contains("\x1b[33m"));
    }

    #[test]
    fn format_cost_zero_returns_none() {
        assert!(format_cost(Some(0.0)).is_none());
        assert!(format_cost(None).is_none());
    }

    #[test]
    fn format_duration_seconds() {
        let result = format_duration(Some(30_000));
        assert!(result.is_some());
        let s = result.unwrap();
        assert!(s.contains("t:30s"), "Got: {s}");
    }

    #[test]
    fn format_duration_minutes() {
        let result = format_duration(Some(180_000));
        assert!(result.is_some());
        let s = result.unwrap();
        assert!(s.contains("t:3m"), "Got: {s}");
    }

    #[test]
    fn format_duration_long() {
        let result = format_duration(Some(1_800_000));
        assert!(result.is_some());
        // 30 min → Yellow
        let s = result.unwrap();
        assert!(s.contains("\x1b[33m"));
    }

    #[test]
    fn format_duration_zero_returns_none() {
        assert!(format_duration(Some(0)).is_none());
        assert!(format_duration(None).is_none());
    }

    #[test]
    fn format_lines_positive_net() {
        let result = format_lines(Some(50), Some(10));
        assert!(result.is_some());
        let s = result.unwrap();
        assert!(s.contains("+40L"), "Got: {s}");
        assert!(s.contains("\x1b[32m")); // Green
    }

    #[test]
    fn format_lines_negative_net() {
        let result = format_lines(Some(5), Some(20));
        assert!(result.is_some());
        let s = result.unwrap();
        assert!(s.contains("-15L"), "Got: {s}");
        assert!(s.contains("\x1b[31m")); // Red
    }

    #[test]
    fn format_lines_zero_net() {
        let result = format_lines(Some(10), Some(10));
        assert!(result.is_some());
        let s = result.unwrap();
        assert!(s.contains("+0L"), "Got: {s}");
        assert!(s.contains("\x1b[33m")); // Yellow
    }

    #[test]
    fn format_lines_all_zero_returns_none() {
        assert!(format_lines(Some(0), Some(0)).is_none());
        assert!(format_lines(None, None).is_none());
    }

    #[test]
    fn full_metrics_with_all_fields() {
        let c = cost(Some(0.042), Some(180_000), Some(50), Some(10));
        let result = format_session_metrics(&c);
        assert!(result.contains("|"));
        assert!(result.contains("$0.042"));
        assert!(result.contains("t:3m"));
        assert!(result.contains("+40L"));
    }
}
