---
name: rust-generator
description: Generate production-ready Rust code. Use when creating Rust applications, CLI tools, libraries, or async services.
---

# Rust Code Generator

Generate production-ready Rust code following best practices.

## Output Requirements

- Edition 2024, `rust-version = "1.93"`
- `unsafe_code` forbidden via `[lints.rust]` unless explicitly justified
- Clippy lints enabled: `all`, `pedantic`, `nursery` as warnings
- Custom errors defined with `thiserror`; application errors use `anyhow`
- Module files preferred over `mod.rs` (e.g., `handlers.rs` + `handlers/` directory)
- Tokio async runtime for concurrent operations
- Structured logging with `tracing` crate
- CLI argument parsing with `clap` (derive API)
- Release profile: `lto = true`, `codegen-units = 1`, `panic = "abort"`

## Project Structure

```
project/
├── Cargo.toml
├── src/
│   ├── main.rs          # Entry point with Clap
│   ├── lib.rs           # Core library
│   ├── error.rs         # Custom error types
│   ├── config.rs        # Configuration
│   ├── handlers.rs      # Parent module
│   └── handlers/
│       ├── auth.rs
│       └── user.rs
└── tests/
    └── integration_test.rs
```

## Cargo.toml Constraints

```toml
[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
```

## Error Handling

- Library code: `thiserror` with typed error enum and `#[from]` for conversions
- Application code: `anyhow::Result` with `.context()` for error messages
- Error propagation via `?` operator

## Ownership & Borrowing

- Take `&str` not `String` for read-only string parameters
- Take ownership (`String`) only when storing or transferring
- Use `Cow<'_, str>` when flexibility between owned/borrowed is needed
- Explicit lifetime annotations only when compiler cannot infer

## CLI Flag Convention (GNU/POSIX)

| Flag | Purpose |
|------|---------|
| `-v`, `--verbose` | Verbose output |
| `-V`, `--version` | Version info (auto-registered by `#[command(version)]`) |

## Async Patterns

- Graceful shutdown via `tokio::select!` with `signal::ctrl_c()`
- Concurrent execution via `futures::future::join_all`

## Version Control

- Binary projects: `Cargo.lock` must be committed for reproducible builds

## Security

- Audit dependencies with `cargo audit`
- Use `secrecy` crate for sensitive data
- Use `ring` or `rustls` for cryptography
- Validate all external inputs

## Quality Commands

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test --verbose
cargo audit
```
