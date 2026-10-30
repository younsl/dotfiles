use crate::color::Color;
use std::process::Command;

pub fn format_usage() -> Option<String> {
    let sysctl = read_sysctl()?;

    let parts: Vec<String> = [
        ("cpu", cpu_percent(&sysctl)),
        (
            "mem",
            read_vm_stat().and_then(|vm| mem_percent(&sysctl, &vm)),
        ),
    ]
    .into_iter()
    .filter_map(|(label, percent)| Some(format_percent(label, percent?)))
    .collect();

    if parts.is_empty() {
        None
    } else {
        Some(parts.join(" "))
    }
}

fn format_percent(label: &str, percent: f64) -> String {
    let color = match percent {
        p if p >= 90.0 => Color::Red,
        p if p >= 70.0 => Color::Yellow,
        _ => Color::Green,
    };

    format!(
        "{} {}",
        Color::Gray.paint(label),
        color.paint(&format!("{percent:.0}%"))
    )
}

fn read_sysctl() -> Option<String> {
    run("sysctl", &["-n", "hw.ncpu", "hw.memsize", "vm.loadavg"])
}

fn read_vm_stat() -> Option<String> {
    run("vm_stat", &[])
}

fn run(program: &str, args: &[&str]) -> Option<String> {
    let output = Command::new(program).args(args).output().ok()?;
    if !output.status.success() {
        return None;
    }
    String::from_utf8(output.stdout).ok()
}

/// `sysctl -n hw.ncpu hw.memsize vm.loadavg` prints one value per line,
/// with the load averages as `{ 2.52 2.66 3.07 }`.
fn cpu_percent(sysctl: &str) -> Option<f64> {
    let mut lines = sysctl.lines();
    let ncpu: f64 = lines.next()?.trim().parse().ok()?;
    let load1: f64 = lines
        .nth(1)?
        .trim_matches(|c: char| c == '{' || c == '}' || c.is_whitespace())
        .split_whitespace()
        .next()?
        .parse()
        .ok()?;

    if ncpu <= 0.0 {
        return None;
    }
    Some((load1 / ncpu * 100.0).min(100.0))
}

fn mem_percent(sysctl: &str, vm_stat: &str) -> Option<f64> {
    let memsize: f64 = sysctl.lines().nth(1)?.trim().parse().ok()?;
    let page_size = parse_page_size(vm_stat)?;

    let used_pages: f64 = [
        "Pages active",
        "Pages wired down",
        "Pages occupied by compressor",
    ]
    .iter()
    .filter_map(|key| parse_pages(vm_stat, key))
    .sum();

    if memsize <= 0.0 {
        return None;
    }
    Some((used_pages * page_size / memsize * 100.0).min(100.0))
}

fn parse_page_size(vm_stat: &str) -> Option<f64> {
    vm_stat
        .lines()
        .next()?
        .split("page size of ")
        .nth(1)?
        .split_whitespace()
        .next()?
        .parse()
        .ok()
}

fn parse_pages(vm_stat: &str, key: &str) -> Option<f64> {
    vm_stat
        .lines()
        .find(|line| line.starts_with(key))?
        .rsplit(':')
        .next()?
        .trim()
        .trim_end_matches('.')
        .parse()
        .ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    const SYSCTL: &str = "10\n34359738368\n{ 2.52 2.66 3.07 }\n";
    const VM_STAT: &str = concat!(
        "Mach Virtual Memory Statistics: (page size of 16384 bytes)\n",
        "Pages free:                                    60501.\n",
        "Pages active:                                 886675.\n",
        "Pages inactive:                               866897.\n",
        "Pages wired down:                             185885.\n",
        "Pages occupied by compressor:                  37759.\n",
    );

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
    fn cpu_percent_from_load_average() {
        let percent = cpu_percent(SYSCTL).unwrap();
        assert!((percent - 25.2).abs() < 0.001, "got {percent}");
    }

    #[test]
    fn cpu_percent_clamped_to_hundred() {
        assert_eq!(cpu_percent("4\n1024\n{ 12.0 8.0 6.0 }\n"), Some(100.0));
    }

    #[test]
    fn cpu_percent_rejects_malformed() {
        assert!(cpu_percent("").is_none());
        assert!(cpu_percent("0\n1024\n{ 1.0 1.0 1.0 }\n").is_none());
    }

    #[test]
    fn mem_percent_from_vm_stat() {
        // (886675 + 185885 + 37759) pages * 16384 B / 32 GiB
        let percent = mem_percent(SYSCTL, VM_STAT).unwrap();
        assert!((percent - 52.9).abs() < 0.1, "got {percent}");
    }

    #[test]
    fn mem_percent_rejects_malformed() {
        assert!(mem_percent("10\n0\n", VM_STAT).is_none());
        assert!(mem_percent(SYSCTL, "no page size here").is_none());
    }

    #[test]
    fn page_size_and_pages_parse() {
        assert_eq!(parse_page_size(VM_STAT), Some(16384.0));
        assert_eq!(parse_pages(VM_STAT, "Pages active"), Some(886675.0));
        assert_eq!(parse_pages(VM_STAT, "Pages nonexistent"), None);
    }

    #[test]
    fn usage_is_one_segment() {
        let plain = strip(&format_usage().unwrap());
        assert!(plain.starts_with("cpu "), "got {plain}");
        assert!(plain.contains(" mem "), "got {plain}");
    }

    #[test]
    fn format_percent_colors_and_label() {
        assert_eq!(strip(&format_percent("cpu", 25.2)), "cpu 25%");
        assert!(format_percent("cpu", 95.0).contains("\x1b[31m"));
        assert!(format_percent("mem", 75.0).contains("\x1b[33m"));
        assert!(format_percent("mem", 20.0).contains("\x1b[32m"));
    }
}
