---
name: rust-generator
description: Generate production-ready Rust code. Use when creating Rust applications, CLI tools, libraries, or async services.
---

# Rust Code Generator

Generate production-ready Rust code following best practices.

## Output Requirements

- Edition 2024, `rust-version = "1.94"`
- `unsafe_code` forbidden via `[lints.rust]` unless explicitly justified
- Clippy lints enabled: `all`, `pedantic`, `nursery` as warnings
- Custom errors defined with `thiserror`; application errors use `anyhow`
- Module files preferred over `mod.rs` (e.g., `handlers.rs` + `handlers/` directory)
- Tokio async runtime for concurrent operations
- Structured logging with `tracing` crate
- CLI argument parsing with `clap` (derive API)
- Release profile: `opt-level = 3`, `lto = true`, `codegen-units = 1`, `strip = true`

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
opt-level = 3
lto = true
codegen-units = 1
strip = true
```

## Build-Time Metadata

- `build.rs` injects `BUILD_COMMIT` (short git hash) and `BUILD_DATE` (YYYY-MM-DD) via `cargo:rustc-env`
- Use `const_format` crate for compile-time string formatting of version info
- Add `cargo:rerun-if-changed=.git/HEAD` to rebuild on commit changes

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
