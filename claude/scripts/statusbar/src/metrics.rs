use crate::color::Color;
use crate::input::CostData;

pub fn format_session_metrics(cost: &CostData) -> Option<String> {
    format_lines(cost.total_lines_added, cost.total_lines_removed)
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

    fn cost(added: Option<i64>, removed: Option<i64>) -> CostData {
        CostData {
            total_lines_added: added,
            total_lines_removed: removed,
        }
    }

    #[test]
    fn empty_cost_returns_empty() {
        let c = cost(None, None);
        assert!(format_session_metrics(&c).is_none());
    }

    #[test]
    fn zero_values_returns_empty() {
        let c = cost(Some(0), Some(0));
        assert!(format_session_metrics(&c).is_none());
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
    fn only_line_diff_is_shown() {
        let c = cost(Some(50), Some(10));
        let result = format_session_metrics(&c).unwrap();
        assert!(result.contains("+40L"));
        assert!(!result.contains("$"));
        assert!(!result.contains("t:"));
    }
}
