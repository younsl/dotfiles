mod config;
mod error;
mod launchd;
mod policy;
mod sampler;

use std::time::Instant;

use anyhow::Result;
use clap::Parser;
use tokio::signal::unix::{SignalKind, signal};
use tokio::time::{MissedTickBehavior, interval};
use tracing::{debug, error, info, warn};
use tracing_subscriber::EnvFilter;

use crate::config::{Args, Config};
use crate::policy::{Decision, Tracker};
use crate::sampler::Sampler;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_ansi(false)
        .with_writer(std::io::stderr)
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let config = Config::try_from(Args::parse())?;
    info!(
        service = %config.service,
        cpu_threshold = config.policy.cpu_threshold,
        sustain_checks = config.policy.sustain_checks,
        interval_secs = config.interval.as_secs(),
        cooldown_secs = config.policy.cooldown.as_secs(),
        dry_run = config.dry_run,
        commit = env!("BUILD_COMMIT"),
        "starting"
    );

    let mut sampler = Sampler::new()?;
    let mut tracker = Tracker::new(config.policy);
    let mut sigterm = signal(SignalKind::terminate())?;
    let mut ticker = interval(config.interval);
    ticker.set_missed_tick_behavior(MissedTickBehavior::Delay);
    ticker.tick().await;

    loop {
        tokio::select! {
            _ = ticker.tick() => check(&config, &mut sampler, &mut tracker).await,
            _ = tokio::signal::ctrl_c() => break,
            _ = sigterm.recv() => break,
        }
    }

    info!("shutting down");
    Ok(())
}

async fn check(config: &Config, sampler: &mut Sampler, tracker: &mut Tracker) {
    let pid = match launchd::service_pid(&config.service).await {
        Ok(Some(pid)) => pid,
        Ok(None) => {
            tracker.reset();
            debug!(service = %config.service, "service not running");
            return;
        }
        Err(err) => {
            tracker.reset();
            warn!(error = %err, "failed to look up service pid");
            return;
        }
    };
    let Some(cpu) = sampler.cpu_usage(pid) else {
        tracker.reset();
        debug!(pid, "process exited before sampling");
        return;
    };
    let cpu_text = format!("{cpu:.1}");

    match tracker.observe(cpu, Instant::now()) {
        Decision::Normal => {
            debug!(pid, cpu = %cpu_text, "normal");
        }
        Decision::High { count } => warn!(
            pid,
            cpu = %cpu_text,
            check = count,
            of = config.policy.sustain_checks,
            "high cpu"
        ),
        Decision::Cooldown { remaining } => warn!(
            pid,
            cpu = %cpu_text,
            remaining_secs = remaining.as_millis().div_ceil(1000),
            "skip restart: cooldown"
        ),
        Decision::Restart => {
            tracker.record_restart(Instant::now());
            if config.dry_run {
                info!(pid, cpu = %cpu_text, service = %config.service, "dry-run: would restart");
                return;
            }
            match launchd::kickstart(&config.service).await {
                Ok(()) => {
                    info!(pid, cpu = %cpu_text, service = %config.service, "restarted");
                }
                Err(err) => error!(error = %err, "restart failed"),
            }
        }
    }
}
