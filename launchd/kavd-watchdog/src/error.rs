#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("cpu threshold must be a positive number, got {0}")]
    InvalidThreshold(f32),
    #[error("sustain checks must be at least 1")]
    ZeroSustainChecks,
    #[error("interval must be at least 1 second")]
    ZeroInterval,
}
