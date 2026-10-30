---
name: rust-generator
description: Write Rust services and CLIs with SRP module layout, 2018-style modules, strict lints, and static multi-arch packaging.
when_to_use: Creating Rust applications, CLI tools, libraries, or async services, e.g. "Rust로 작성", "Rust로 포팅", "에드온 개발". Not for Rust toolchain or MSRV bumps (use rust-bump-rerelease), Dockerfile contents (use dockerfile-generator), release workflows (use github-actions-generator), or chart templates (use helm-chart).
argument-hint: "[project purpose]"
license: Apache-2.0
compatibility: cargo with rustfmt and clippy, plus cargo-zigbuild, zig 0.15.2, and the x86_64 and aarch64 musl targets for addon packaging
metadata:
  version: "1.2.0"
  category: generator
  related: dockerfile-generator helm-chart github-actions-generator done-check rust-bump-rerelease
allowed-tools: Bash(cargo *) Bash(rustc --version) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Rust Code Generator

## Output Requirements

- Edition 2024; `rust-version` = the local stable toolchain (`rustc --version`) in full semver (`"x.y.z"`, never `"x.y"`), matching sibling crates in the repo. Bumping an existing project's `rust-version` belongs to rust-bump-rerelease
- `unsafe_code` forbidden via `[lints.rust]`
- Clippy lints: `all`, `pedantic`, `nursery` as warnings
- Errors: `thiserror` enums per layer, `anyhow` only in `main.rs` and the orchestration loop, never in layer directories
- SDK error wrappers (`kube::Error`, AWS SDK errors) live in their layer, e.g. `k8s/error.rs`. Root `error.rs` holds config and domain errors only
- Async runtime: `tokio`
- Logging: `tracing` + `tracing-subscriber`
- CLI: `clap` derive API, config flags fall back to env vars via `env`
- TLS: rustls only (`rustls-tls` features), no `openssl-sys` or `native-tls` in `Cargo.lock`
- Module style: sibling file pattern (`parent.rs` + `parent/`), never `mod.rs`

## Project Structure (SRP)

Split by domain responsibility. Each layer directory owns its API calls and SDK error types. `main.rs` may construct clients to wire them in.

```
src/
├── main.rs           # Orchestration only
├── config.rs         # Config loading and validation
├── error.rs          # Config and domain errors, no SDK types
├── types.rs          # Shared domain types
├── aws.rs            # Declares aws/ submodules
├── aws/
│   ├── error.rs
│   └── <service>.rs
├── k8s.rs
├── k8s/
│   ├── error.rs
│   └── leader.rs
├── observability.rs
└── observability/
    ├── metrics.rs
    └── server.rs
```

| Directory | Responsibility | External deps |
|-----------|---------------|---------------|
| root | Shared domain logic, config, wiring | no client SDK crates beyond client construction in `main.rs` |
| `aws/` | AWS API communication | `aws-sdk-*` |
| `k8s/` | Kubernetes API communication | `kube`, `k8s-openapi` |
| `observability/` | Metrics exposition and HTTP | `prometheus`, `axum` |

## Cargo.toml

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
strip = true
panic = "abort"
```

## Build-Time Metadata

- `build.rs` injects `BUILD_COMMIT` and `BUILD_DATE` via `cargo:rustc-env`
- Rerun paths come from `git rev-parse --path-format=absolute --git-path HEAD` and the current branch ref, emitted only when they exist. Never a literal `.git/HEAD`: it is missing in a crate below the repo root, so cargo reruns every build

## Async Patterns

- Services: graceful shutdown via `tokio::select!` on `signal::ctrl_c()` and SIGTERM. One-shot CLIs exit on either signal
- Concurrency: `JoinSet` + `Semaphore` for bounded parallelism

## Packaging

- New Kubernetes addons are Rust in `box/addons/<name>/`: Makefile `zigbuild` target builds static musl binaries for amd64 and arm64 with cargo-zigbuild, shipped in a `scratch` image (see dockerfile-generator) with a chart at `box/addons/<name>/charts/<name>/` (see helm-chart)
- A new addon or CLI joins its release workflow and detect list per github-actions-generator. Unregistered projects never ship
- CLIs live in `box/cli/<name>/` and release through `_release-rust-cli.yml`, no Dockerfile or chart. When no repo is named, state the location assumed
- Comments follow the global Code Comments rule; public items get doc comments only when behavior is not obvious from the signature

## Validation

- done-check Rust gate passes (`cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`)
- Glob `src/**/mod.rs` returns nothing
- A second `cargo build -v` reports `Fresh` for the crate
- `Cargo.lock` has no `openssl-sys` or `native-tls` package
- Addons: `make zigbuild` produces both musl binaries
