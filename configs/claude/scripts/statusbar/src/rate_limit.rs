use crate::color::Color;
use crate::input::{RateLimitWindow, RateLimits};
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

pub fn format_limits(limits: Option<&RateLimits>, cache_path: &Path) -> Vec<String> {
    let resolved = resolve(limits, cache_path);

    [
        ("5h", resolved.five_hour.as_ref()),
        ("week", resolved.seven_day.as_ref()),
    ]
    .into_iter()
    .filter_map(|(label, window)| format_window(label, window?))
    .collect()
}

fn resolve(limits: Option<&RateLimits>, cache_path: &Path) -> RateLimits {
    let fresh = limits.map(clone_limits).unwrap_or_default();
    if fresh.five_hour.is_some() || fresh.seven_day.is_some() {
        write_cache(cache_path, &fresh);
        return fresh;
    }

    read_cache(cache_path).unwrap_or(fresh)
}

fn clone_limits(limits: &RateLimits) -> RateLimits {
    RateLimits {
        five_hour: limits.five_hour.as_ref().map(clone_window),
        seven_day: limits.seven_day.as_ref().map(clone_window),
    }
}

fn clone_window(window: &RateLimitWindow) -> RateLimitWindow {
    RateLimitWindow {
        used_percentage: window.used_percentage,
        resets_at: window.resets_at,
    }
}

fn format_window(label: &str, window: &RateLimitWindow) -> Option<String> {
    let percent = window.used_percentage?;

    let color = match percent {
        p if p >= 90.0 => Color::Red,
        p if p >= 70.0 => Color::Yellow,
        _ => Color::Green,
    };

    Some(format!(
        "{} {}",
        Color::Gray.paint(label),
        color.paint(&format!("{percent:.0}%"))
    ))
}

fn read_cache(path: &Path) -> Option<RateLimits> {
    let cached: RateLimits = serde_json::from_str(&fs::read_to_string(path).ok()?).ok()?;
    let now = now_secs();
    let unexpired = |window: Option<RateLimitWindow>| {
        window.filter(|w| w.resets_at.is_none_or(|reset| now < reset))
    };

    Some(RateLimits {
        five_hour: unexpired(cached.five_hour),
        seven_day: unexpired(cached.seven_day),
    })
}

fn write_cache(path: &Path, limits: &RateLimits) {
    let payload = match serde_json::to_string(limits) {
        Ok(payload) => payload,
        Err(_) => return,
    };
    if let Some(parent) = path.parent() {
        let _ = fs::create_dir_all(parent);
    }
    let tmp = path.with_extension(format!("tmp{}", std::process::id()));
    if File::create(&tmp)
        .and_then(|mut f| f.write_all(payload.as_bytes()))
        .is_ok()
    {
        let _ = fs::rename(&tmp, path);
    }
}

fn now_secs() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn window(used: f64, resets_in: i64) -> RateLimitWindow {
        RateLimitWindow {
            used_percentage: Some(used),
            resets_at: Some(now_secs() + resets_in),
        }
    }

    fn cache_path(name: &str) -> std::path::PathBuf {
        let path = std::env::temp_dir().join(format!("statusbar-limits-{name}.json"));
        let _ = fs::remove_file(&path);
        path
    }

    fn strip(s: &str) -> String {
        let mut out = String::new();
        let mut in_escape = false;
        for c in s.chars() {
            match (in_escape, c) {
                (false, '\x1b') => in_escape = true,
                (true, 'm') => in_escape = false,
                (true, _) => {}
                (false, c) => out.push(c),
            }
        }
        out
    }

    #[test]
    fn both_windows() {
        let limits = RateLimits {
            five_hour: Some(window(22.0, 3_600)),
            seven_day: Some(window(44.0, 86_400)),
        };
        let parts = format_limits(Some(&limits), &cache_path("both"));
        assert_eq!(strip(&parts[0]), "5h 22%");
        assert_eq!(strip(&parts[1]), "week 44%");
    }

    #[test]
    fn empty_when_absent_and_uncached() {
        assert!(format_limits(None, &cache_path("absent")).is_empty());
    }

    #[test]
    fn falls_back_to_cached_values() {
        let path = cache_path("fallback");
        let limits = RateLimits {
            five_hour: Some(window(23.0, 3_600)),
            seven_day: Some(window(44.0, 86_400)),
        };
        format_limits(Some(&limits), &path);

        let parts = format_limits(None, &path);
        assert_eq!(strip(&parts[0]), "5h 23%");
        assert_eq!(strip(&parts[1]), "week 44%");
    }

    #[test]
    fn drops_expired_cache_entries() {
        let path = cache_path("expired");
        let limits = RateLimits {
            five_hour: Some(window(23.0, -60)),
            seven_day: Some(window(44.0, 86_400)),
        };
        format_limits(Some(&limits), &path);

        let parts = format_limits(None, &path);
        assert_eq!(parts.len(), 1);
        assert_eq!(strip(&parts[0]), "week 44%");
    }

    #[test]
    fn rounds_percentage() {
        let limits = RateLimits {
            five_hour: Some(window(99.6, 3_600)),
            seven_day: None,
        };
        let parts = format_limits(Some(&limits), &cache_path("round"));
        assert_eq!(strip(&parts[0]), "5h 100%");
    }

    #[test]
    fn colors_by_severity() {
        let high = format_window("5h", &window(95.0, 60)).unwrap();
        let mid = format_window("5h", &window(75.0, 60)).unwrap();
        let low = format_window("5h", &window(10.0, 60)).unwrap();
        assert!(high.contains("\x1b[31m"));
        assert!(mid.contains("\x1b[33m"));
        assert!(low.contains("\x1b[32m"));
    }
}
