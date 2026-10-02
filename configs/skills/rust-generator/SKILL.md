---
name: rust-generator
description: Write Rust services and CLIs with SRP module layout, 2018-style modules, strict lints, and static multi-arch packaging.
when_to_use: Creating Rust applications, CLI tools, libraries, or async services, e.g. "Rust로 작성", "Rust로 포팅", "에드온 개발".
argument-hint: "[project purpose]"
license: Apache-2.0
compatibility: cargo with rustfmt and clippy
metadata:
  version: "1.1.0"
  category: generator
  related: dockerfile-generator done-check rust-bump-rerelease
allowed-tools: Bash(cargo *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Rust Code Generator

## Output Requirements

- Edition 2024; `rust-version` = current stable MSRV in full semver (`"1.96.0"`, never `"1.96"`). Existing projects bump it via the `rust-bump-rerelease` skill: do not pin a version here.
- `unsafe_code` forbidden via `[lints.rust]`
- Clippy lints: `all`, `pedantic`, `nursery` as warnings
- Errors: `thiserror` for library types, `anyhow` for application context
- Async runtime: `tokio`
- Logging: `tracing` + `tracing-subscriber`
- CLI: `clap` derive API
- Module style: sibling file pattern (`parent.rs` + `parent/`), never `mod.rs`

## Project Structure (SRP)

Split by domain responsibility. Each directory isolates its external dependencies.

```
src/
├── main.rs           # Orchestration only
├── config.rs         # Config loading and validation
├── error.rs          # Error types
├── types.rs          # Shared domain types
├── aws.rs            # Module declaration for aws/
├── aws/
│   ├── discovery.rs
│   └── collector.rs
├── k8s.rs
├── k8s/
│   └── leader.rs
├── observability.rs
└── observability/
    ├── metrics.rs
    └── server.rs
```

| Directory | Responsibility | External deps |
|-----------|---------------|---------------|
| root | Shared domain logic | serde only |
| `aws/` | AWS API communication | `aws-sdk-*` |
| `k8s/` | Kubernetes API communication | `kube`, `k8s-openapi` |
| `observability/` | Metrics exposition and HTTP | `prometheus`, `axum` |

### Module declaration (Edition 2018+)

Use sibling file pattern. `src/aws.rs` declares submodules of `src/aws/`:

```rust
// src/aws.rs
pub mod collector;
pub mod discovery;

// src/main.rs
mod aws;
use crate::aws::collector::AwsPiCollector;
```

## Cargo.toml

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

- `build.rs` injects `BUILD_COMMIT` and `BUILD_DATE` via `cargo:rustc-env`
- `cargo:rerun-if-changed=.git/HEAD` to rebuild on commit changes

## Async Patterns

- Graceful shutdown: `tokio::select!` with `signal::ctrl_c()` and SIGTERM
- Concurrency: `JoinSet` + `Semaphore` for bounded parallelism

## Packaging

- New Kubernetes addons are Rust, built with cargo-zigbuild as static musl binaries for amd64 and arm64, shipped in a `scratch` image (see dockerfile-generator) with a chart under `charts/<name>/`
- `[profile.release]` adds `panic = "abort"`
- Comments follow the global Code Comments rule; public items get doc comments only when behavior is not obvious from the signature
