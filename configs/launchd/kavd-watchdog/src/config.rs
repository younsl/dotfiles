use std::time::Duration;

use clap::Parser;

use crate::error::ConfigError;
use crate::policy::Policy;

/// Restart a launchd service when its process stays pinned on CPU.
#[derive(Debug, Parser)]
#[command(
    version = concat!(env!("CARGO_PKG_VERSION"), " (", env!("BUILD_COMMIT"), " ", env!("BUILD_DATE"), ")"),
    about
)]
pub struct Args {
    /// launchd service target to watch and kickstart, e.g. system/com.example.daemon
    #[arg(long, env = "KAVD_WATCHDOG_SERVICE")]
    service: String,

    /// CPU percentage at or above which a check counts as high (100 = one core)
    #[arg(long, env = "KAVD_WATCHDOG_CPU_THRESHOLD", default_value_t = 150.0)]
    cpu_threshold: f32,

    /// Consecutive high checks before a restart
    #[arg(long, env = "KAVD_WATCHDOG_SUSTAIN_CHECKS", default_value_t = 5)]
    sustain_checks: u32,

    /// Seconds between checks; CPU is averaged over this window
    #[arg(long, env = "KAVD_WATCHDOG_INTERVAL_SECONDS", default_value_t = 60)]
    interval_seconds: u64,

    /// Minimum seconds between restarts
    #[arg(long, env = "KAVD_WATCHDOG_COOLDOWN_SECONDS", default_value_t = 3600)]
    cooldown_seconds: u64,

    /// Log restart decisions without restarting
    #[arg(long, env = "KAVD_WATCHDOG_DRY_RUN")]
    dry_run: bool,
}

#[derive(Debug)]
pub struct Config {
    pub service: String,
    pub interval: Duration,
    pub policy: Policy,
    pub dry_run: bool,
}

impl TryFrom<Args> for Config {
    type Error = ConfigError;

    fn try_from(args: Args) -> Result<Self, Self::Error> {
        if !args.cpu_threshold.is_finite() || args.cpu_threshold <= 0.0 {
            return Err(ConfigError::InvalidThreshold(args.cpu_threshold));
        }
        if args.sustain_checks == 0 {
            return Err(ConfigError::ZeroSustainChecks);
        }
        if args.interval_seconds == 0 {
            return Err(ConfigError::ZeroInterval);
        }

        Ok(Self {
            service: args.service,
            interval: Duration::from_secs(args.interval_seconds),
            policy: Policy {
                cpu_threshold: args.cpu_threshold,
                sustain_checks: args.sustain_checks,
                cooldown: Duration::from_secs(args.cooldown_seconds),
            },
            dry_run: args.dry_run,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse(extra: &[&str]) -> Result<Config, ConfigError> {
        let base = ["kavd-watchdog", "--service", "system/s"];
        Config::try_from(Args::parse_from(base.iter().chain(extra)))
    }

    #[test]
    fn defaults_are_valid() {
        let config = parse(&[]).unwrap();
        assert_eq!(config.interval, Duration::from_secs(60));
        assert_eq!(config.policy.sustain_checks, 5);
        assert_eq!(config.policy.cooldown, Duration::from_secs(3600));
        assert!(!config.dry_run);
    }

    #[test]
    fn rejects_non_positive_threshold() {
        assert!(matches!(
            parse(&["--cpu-threshold", "0"]),
            Err(ConfigError::InvalidThreshold(_))
        ));
    }

    #[test]
    fn rejects_zero_sustain_checks() {
        assert!(matches!(
            parse(&["--sustain-checks", "0"]),
            Err(ConfigError::ZeroSustainChecks)
        ));
    }

    #[test]
    fn rejects_zero_interval() {
        assert!(matches!(
            parse(&["--interval-seconds", "0"]),
            Err(ConfigError::ZeroInterval)
        ));
    }
}
