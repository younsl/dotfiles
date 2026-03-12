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
