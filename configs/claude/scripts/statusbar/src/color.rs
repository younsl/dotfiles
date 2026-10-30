use std::fmt;

#[derive(Clone, Copy)]
pub enum Color {
    Red,
    RedBold,
    LightRed,
    Yellow,
    BrightYellow,
    Green,
    Blue,
    Gray,
    Bold,
    Reset,
}

impl Color {
    const fn code(self) -> &'static str {
        match self {
            Self::Red => "\x1b[31m",
            Self::RedBold => "\x1b[31;1m",
            Self::LightRed => "\x1b[91m",
            Self::Yellow => "\x1b[33m",
            Self::BrightYellow => "\x1b[93m",
            Self::Green => "\x1b[32m",
            Self::Blue => "\x1b[94m",
            Self::Gray => "\x1b[90m",
            Self::Bold => "\x1b[1m",
            Self::Reset => "\x1b[0m",
        }
    }

    pub fn paint(self, text: &str) -> String {
        format!("{}{}{}", self.code(), text, Self::Reset.code())
    }
}

impl fmt::Display for Color {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.code())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn paint_wraps_text_with_ansi_codes() {
        let result = Color::Red.paint("hello");
        assert!(result.starts_with("\x1b[31m"));
        assert!(result.contains("hello"));
        assert!(result.ends_with("\x1b[0m"));
    }

    #[test]
    fn paint_each_variant() {
        let variants = [
            (Color::Red, "\x1b[31m"),
            (Color::RedBold, "\x1b[31;1m"),
            (Color::LightRed, "\x1b[91m"),
            (Color::Yellow, "\x1b[33m"),
            (Color::BrightYellow, "\x1b[93m"),
            (Color::Green, "\x1b[32m"),
            (Color::Blue, "\x1b[94m"),
            (Color::Gray, "\x1b[90m"),
            (Color::Bold, "\x1b[1m"),
            (Color::Reset, "\x1b[0m"),
        ];

        for (color, expected_code) in variants {
            let result = color.paint("x");
            assert!(
                result.starts_with(expected_code),
                "Failed for {expected_code}"
            );
        }
    }

    #[test]
    fn display_trait_outputs_code() {
        let s = format!("{}", Color::Green);
        assert_eq!(s, "\x1b[32m");
    }

    #[test]
    fn paint_empty_string() {
        let result = Color::Blue.paint("");
        assert_eq!(result, "\x1b[94m\x1b[0m");
    }
}
