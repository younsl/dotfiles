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
            Self::Critical => "!!",
            Self::High => "!",
            Self::Warning => "*",
            Self::Moderate | Self::Normal => "",
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_percent_critical() {
        assert!(matches!(Level::from_percent(95.0), Level::Critical));
        assert!(matches!(Level::from_percent(100.0), Level::Critical));
        assert!(matches!(Level::from_percent(99.9), Level::Critical));
    }

    #[test]
    fn from_percent_high() {
        assert!(matches!(Level::from_percent(90.0), Level::High));
        assert!(matches!(Level::from_percent(94.9), Level::High));
    }

    #[test]
    fn from_percent_warning() {
        assert!(matches!(Level::from_percent(75.0), Level::Warning));
        assert!(matches!(Level::from_percent(89.9), Level::Warning));
    }

    #[test]
    fn from_percent_moderate() {
        assert!(matches!(Level::from_percent(50.0), Level::Moderate));
        assert!(matches!(Level::from_percent(74.9), Level::Moderate));
    }

    #[test]
    fn from_percent_normal() {
        assert!(matches!(Level::from_percent(0.0), Level::Normal));
        assert!(matches!(Level::from_percent(49.9), Level::Normal));
    }

    #[test]
    fn icon_values() {
        assert_eq!(Level::Critical.icon(), "!!");
        assert_eq!(Level::High.icon(), "!");
        assert_eq!(Level::Warning.icon(), "*");
        assert_eq!(Level::Moderate.icon(), "");
        assert_eq!(Level::Normal.icon(), "");
    }

    #[test]
    fn model_color_values() {
        // Critical and High → Red
        let _ = Level::Critical.model_color();
        let _ = Level::High.model_color();
        // Warning → Yellow
        let _ = Level::Warning.model_color();
        // Moderate/Normal → Green
        let _ = Level::Moderate.model_color();
        let _ = Level::Normal.model_color();
    }

    #[test]
    fn color_values() {
        let _ = Level::Critical.color();
        let _ = Level::High.color();
        let _ = Level::Warning.color();
        let _ = Level::Moderate.color();
        let _ = Level::Normal.color();
    }
}
