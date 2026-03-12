use crate::color::Color;

#[derive(Clone, Copy)]
pub enum Level {
    Critical,
    High,
    Warning,
    Moderate,
    Normal,
}

impl Level {
    pub fn from_percent(percent: f64) -> Self {
        match percent {
            p if p >= 95.0 => Self::Critical,
            p if p >= 90.0 => Self::High,
            p if p >= 75.0 => Self::Warning,
            p if p >= 50.0 => Self::Moderate,
            _ => Self::Normal,
        }
    }

    pub fn color(self) -> Color {
        match self {
            Self::Critical => Color::RedBold,
            Self::High => Color::Red,
            Self::Warning => Color::LightRed,
            Self::Moderate => Color::Yellow,
            Self::Normal => Color::Green,
        }
    }

    pub fn icon(self) -> &'static str {
        match self {
            Self::Critical => "🚨",
            Self::High => "🔴",
            Self::Warning => "🟠",
            Self::Moderate => "🟡",
            Self::Normal => "🟢",
        }
    }

    pub fn model_color(self) -> Color {
        match self {
            Self::Critical | Self::High => Color::Red,
            Self::Warning => Color::Yellow,
            Self::Moderate | Self::Normal => Color::Green,
        }
    }
}
