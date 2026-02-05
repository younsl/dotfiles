# Rust Code Generator

Generate production-ready Rust code following best practices.

## When to Use
- Rust application or library development
- CLI tool development
- Systems programming
- WebAssembly module development

## Core Rules

### 1. Use Edition 2024

Set `edition = "2024"` and `rust-version = "1.93"` in Cargo.toml.

### 2. Forbid Unsafe Code

Add `#![forbid(unsafe_code)]` unless absolutely necessary.

### 3. Use thiserror for Errors

Define custom error types with `thiserror` crate.

### 4. Prefer Module Files over mod.rs

Use `handlers.rs` + `handlers/` instead of `handlers/mod.rs`. Avoids multiple `mod.rs` tabs in editor and makes module structure clearer from filenames.

### 5. Enable Clippy Lints

Set `clippy::all`, `clippy::pedantic`, `clippy::nursery` as warnings.

## Project Structure

Edition 2018+ 권장 모듈 구조 (mod.rs 사용 안 함):

```
project/
├── Cargo.toml
├── Cargo.lock
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── error.rs
│   ├── config.rs
│   ├── handlers.rs        # src/handlers/ 디렉토리의 부모 모듈
│   └── handlers/
│       ├── auth.rs
│       └── user.rs
├── tests/
│   └── integration_test.rs
├── benches/
│   └── benchmark.rs
└── examples/
    └── example.rs
```

### Module Declaration (권장 방식)

```rust
// src/lib.rs
mod error;
mod config;
mod handlers;

pub use error::{AppError, Result};
pub use config::Config;
```

```rust
// src/handlers.rs (디렉토리와 같은 이름의 파일)
mod auth;
mod user;

pub use auth::*;
pub use user::*;
```

## Cargo.toml Template

```toml
[package]
name = "project-name"
version = "0.1.0"
edition = "2024"
rust-version = "1.93"
authors = ["Author <author@example.com>"]
description = "A brief description"
license = "MIT"
repository = "https://github.com/example/project"

[dependencies]
thiserror = "2.0"
anyhow = "1.0"
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.0", features = ["full"] }
tracing = "0.1"

[dev-dependencies]
criterion = "0.5"
tempfile = "3.0"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"

[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"
```

## Error Handling

### Custom Error Type with thiserror

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("configuration error: {0}")]
    Config(String),

    #[error("IO error: {source}")]
    Io {
        #[from]
        source: std::io::Error,
    },

    #[error("parse error at line {line}: {message}")]
    Parse { line: usize, message: String },

    #[error("not found: {0}")]
    NotFound(String),
}

pub type Result<T> = std::result::Result<T, AppError>;
```

### Error Propagation

```rust
// Use ? operator for propagation
fn read_config(path: &Path) -> Result<Config> {
    let content = std::fs::read_to_string(path)?;
    let config: Config = toml::from_str(&content)
        .map_err(|e| AppError::Parse {
            line: e.line().unwrap_or(0),
            message: e.to_string(),
        })?;
    Ok(config)
}

// Use anyhow for application code
use anyhow::{Context, Result};

fn main() -> Result<()> {
    let config = read_config(path)
        .context("failed to read configuration")?;
    Ok(())
}
```

## Ownership & Borrowing

### Function Parameters

```rust
// Take ownership when you need it
fn consume(s: String) { /* ... */ }

// Borrow when you only need to read
fn read(s: &str) { /* ... */ }

// Mutable borrow when you need to modify
fn modify(s: &mut String) { /* ... */ }

// Use Cow for flexibility
use std::borrow::Cow;
fn flexible(s: Cow<'_, str>) { /* ... */ }
```

### Lifetime Annotations

```rust
// Explicit lifetimes when compiler can't infer
struct Parser<'a> {
    input: &'a str,
    position: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        Self { input, position: 0 }
    }

    fn parse(&mut self) -> &'a str {
        &self.input[self.position..]
    }
}
```

## Structs & Enums

### Builder Pattern

```rust
#[derive(Debug, Clone)]
pub struct Config {
    host: String,
    port: u16,
    timeout: Duration,
}

#[derive(Default)]
pub struct ConfigBuilder {
    host: Option<String>,
    port: Option<u16>,
    timeout: Option<Duration>,
}

impl ConfigBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn host(mut self, host: impl Into<String>) -> Self {
        self.host = Some(host.into());
        self
    }

    pub fn port(mut self, port: u16) -> Self {
        self.port = Some(port);
        self
    }

    pub fn build(self) -> Result<Config> {
        Ok(Config {
            host: self.host.ok_or(AppError::Config("host required".into()))?,
            port: self.port.unwrap_or(8080),
            timeout: self.timeout.unwrap_or(Duration::from_secs(30)),
        })
    }
}
```

### Newtype Pattern

```rust
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct UserId(String);

impl UserId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}
```

## Async/Await

### Async Function

```rust
use tokio::time::{sleep, Duration};

async fn fetch_data(url: &str) -> Result<String> {
    let response = reqwest::get(url)
        .await
        .context("request failed")?;

    let body = response
        .text()
        .await
        .context("failed to read body")?;

    Ok(body)
}

// Concurrent execution
async fn fetch_all(urls: Vec<&str>) -> Vec<Result<String>> {
    let futures: Vec<_> = urls.iter().map(|url| fetch_data(url)).collect();
    futures::future::join_all(futures).await
}
```

### Graceful Shutdown

```rust
use tokio::signal;

async fn run_server() -> Result<()> {
    let server = create_server();

    tokio::select! {
        result = server => result?,
        _ = signal::ctrl_c() => {
            tracing::info!("shutdown signal received");
        }
    }

    Ok(())
}
```

## Testing

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_input() {
        let result = parse("valid input");
        assert!(result.is_ok());
    }

    #[test]
    fn test_parse_invalid_input() {
        let result = parse("invalid");
        assert!(matches!(result, Err(AppError::Parse { .. })));
    }
}
```

### Async Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_async_function() {
        let result = fetch_data("https://example.com").await;
        assert!(result.is_ok());
    }
}
```

## Documentation

```rust
/// A configuration for the application.
///
/// # Examples
///
/// ```
/// use mylib::Config;
///
/// let config = Config::builder()
///     .host("localhost")
///     .port(8080)
///     .build()?;
/// ```
///
/// # Errors
///
/// Returns `AppError::Config` if required fields are missing.
pub struct Config { /* ... */ }
```

## Clippy & Formatting

```bash
# Format code
cargo fmt

# Run clippy
cargo clippy -- -W clippy::all -W clippy::pedantic -W clippy::nursery

# Fix automatically
cargo clippy --fix

# Check before commit
cargo fmt --check && cargo clippy -- -D warnings
```

## Security Best Practices

- `unsafe` 블록 사용 최소화 (`#![forbid(unsafe_code)]` 권장)
- 의존성 보안 감사: `cargo audit`
- 입력 검증 철저히 수행
- 민감 데이터는 `secrecy` crate 사용
- 암호화: `ring` 또는 `rustls` 사용
