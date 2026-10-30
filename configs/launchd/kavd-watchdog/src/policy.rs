use std::time::{Duration, Instant};

#[derive(Debug, Clone, Copy)]
pub struct Policy {
    pub cpu_threshold: f32,
    pub sustain_checks: u32,
    pub cooldown: Duration,
}

#[derive(Debug, PartialEq, Eq)]
pub enum Decision {
    Normal,
    High { count: u32 },
    Cooldown { remaining: Duration },
    Restart,
}

#[derive(Debug)]
pub struct Tracker {
    policy: Policy,
    high_count: u32,
    last_restart: Option<Instant>,
}

impl Tracker {
    pub const fn new(policy: Policy) -> Self {
        Self {
            policy,
            high_count: 0,
            last_restart: None,
        }
    }

    pub const fn reset(&mut self) {
        self.high_count = 0;
    }

    pub fn observe(&mut self, cpu: f32, now: Instant) -> Decision {
        if cpu < self.policy.cpu_threshold {
            self.high_count = 0;
            return Decision::Normal;
        }

        self.high_count = self.high_count.saturating_add(1);
        if self.high_count < self.policy.sustain_checks {
            return Decision::High {
                count: self.high_count,
            };
        }

        if let Some(last) = self.last_restart {
            let remaining = self
                .policy
                .cooldown
                .saturating_sub(now.saturating_duration_since(last));
            if !remaining.is_zero() {
                return Decision::Cooldown { remaining };
            }
        }

        Decision::Restart
    }

    pub const fn record_restart(&mut self, now: Instant) {
        self.last_restart = Some(now);
        self.high_count = 0;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const POLICY: Policy = Policy {
        cpu_threshold: 150.0,
        sustain_checks: 3,
        cooldown: Duration::from_hours(1),
    };

    #[test]
    fn below_threshold_is_normal_and_resets_count() {
        let mut tracker = Tracker::new(POLICY);
        let now = Instant::now();
        assert_eq!(tracker.observe(200.0, now), Decision::High { count: 1 });
        assert_eq!(tracker.observe(149.9, now), Decision::Normal);
        assert_eq!(tracker.observe(200.0, now), Decision::High { count: 1 });
    }

    #[test]
    fn restarts_after_sustained_high_checks() {
        let mut tracker = Tracker::new(POLICY);
        let now = Instant::now();
        assert_eq!(tracker.observe(150.0, now), Decision::High { count: 1 });
        assert_eq!(tracker.observe(150.0, now), Decision::High { count: 2 });
        assert_eq!(tracker.observe(150.0, now), Decision::Restart);
    }

    #[test]
    fn cooldown_blocks_restart_until_it_expires() {
        let mut tracker = Tracker::new(POLICY);
        let start = Instant::now();
        tracker.record_restart(start);

        let later = start + Duration::from_mins(10);
        tracker.observe(200.0, later);
        tracker.observe(200.0, later);
        assert_eq!(
            tracker.observe(200.0, later),
            Decision::Cooldown {
                remaining: Duration::from_mins(50)
            }
        );

        let expired = start + POLICY.cooldown;
        assert_eq!(tracker.observe(200.0, expired), Decision::Restart);
    }

    #[test]
    fn record_restart_resets_count() {
        let mut tracker = Tracker::new(POLICY);
        let now = Instant::now();
        tracker.observe(200.0, now);
        tracker.observe(200.0, now);
        tracker.record_restart(now);
        assert_eq!(tracker.observe(200.0, now), Decision::High { count: 1 });
    }

    #[test]
    fn missing_process_reset_clears_count() {
        let mut tracker = Tracker::new(POLICY);
        let now = Instant::now();
        tracker.observe(200.0, now);
        tracker.observe(200.0, now);
        tracker.reset();
        assert_eq!(tracker.observe(200.0, now), Decision::High { count: 1 });
    }
}
