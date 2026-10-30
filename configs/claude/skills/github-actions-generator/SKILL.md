---
name: github-actions-generator
description: Write GitHub Actions workflows, especially release pipelines for multi-arch binaries, containers, and Helm charts, following the user's release mechanics.
when_to_use: Creating or modifying .github/workflows/ files, release or CI pipelines, e.g. "릴리즈 워크플로우 작성", "CI 추가", "QEMU 대신 크로스 컴파일", "hcl validate 스텝 추가". Runner and target rules come from the global AGENTS.md. Not for GitLab CI (use gitlab-ci-arm64), Dockerfile contents (use dockerfile-generator), re-running an existing release (use release-retrigger), or Rust toolchain bumps (use rust-bump-rerelease).
argument-hint: "[workflow purpose]"
license: Apache-2.0
compatibility: actionlint and zizmor optional for validation (zizmor runs through uvx when not installed)
metadata:
  version: "2.1.0"
  category: generator
  related: dockerfile-generator gitlab-ci-arm64 release-retrigger rust-bump-rerelease
allowed-tools: Bash(actionlint *) Bash(zizmor *) Bash(uvx zizmor*) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# GitHub Actions

Pinned runner labels and the four binary targets are global policy (AGENTS.md).

## Release Pipeline Conventions

- A new project joins the existing release workflow for its artifact type (`_release-rust-cli.yml`, `_release-rust-scratch-containers.yml`, `_release-charts.yml`, `release-containers.yml`) as a dispatch option, push path, and detect entry wherever that workflow lists projects. No per-project workflow and no `workflow_call` caller
- A `detect` job reads the version from the artifact itself (Dockerfile `org.opencontainers.image.version`, `Chart.yaml` `version`, `Cargo.toml` `version` for CLIs) and skips versions already published (GHCR tag, or `box/cli/<project>/dist/<version>` on main for CLIs)
- Push events release every project whose version file changed anywhere in the push (`.github/scripts/ci-changed-files.sh`, checkout with `fetch-depth: 0`). Never default a push to one project
- `workflow_dispatch` inputs: a `choice` of projects (named `project`, or `container` in `release-containers.yml`), plus `force` (boolean) to rebuild and overwrite an existing version. `_release-charts.yml` keeps its free `chart` string (empty releases all) and `box/**/Chart.yaml` push path
- Re-releases use `force`, never package deletion
- Gate order: fmt, lint, test, coverage threshold, then build and push; a failed gate skips the push
- Native arm64 runners build arm64; no QEMU emulation for compilation
- Containers that compile inside the Dockerfile push one platform per native runner by digest (`push-by-digest=true`), then a merge job runs `docker buildx imagetools create` with the version tag
- musl scratch-container builds keep the exact pins `ziglang==0.15.2` (newer zig leaks RSS in static musl binaries) and `cargo-zigbuild --version 0.23.0` (the minimum that accepts rustc 1.98+ aarch64 linker args), then copy prebuilt binaries into one two-platform buildx call
- CLI binaries build natively per target runner without zigbuild
- Images and OCI charts publish to GHCR under the repo owner. CLI archives are committed to `box/cli/<project>/dist/<version>/` on main with `SHA256SUMS`
- Actions pin to a major tag (`@v6`), matching the repo, not a commit SHA

## Validation

- `actionlint` passes with `.github/actionlint.yaml` declaring `self-hosted-runner.labels: [ubuntu-26.04, ubuntu-26.04-arm]` (actionlint 1.7.12 does not know these labels). Add that file when missing, never pass `-ignore`
- `zizmor --min-severity high` (or `uvx zizmor`) adds no high findings beyond `unpinned-uses`
- In workflows with a project `choice`, every dispatch option has a project directory and a detect entry (`case` arm or `ci-rust-projects.json` key), and every project in push `paths` is a dispatch option
