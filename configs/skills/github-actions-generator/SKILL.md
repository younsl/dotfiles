---
name: github-actions-generator
description: Write GitHub Actions workflows, especially release pipelines for multi-arch binaries, containers, and Helm charts, following the user's release mechanics.
when_to_use: Creating or modifying .github/workflows/ files, release or CI pipelines, e.g. "릴리즈 워크플로우 작성", "CI 추가", "QEMU 대신 크로스 컴파일", "hcl validate 스텝 추가". Runner and target rules come from the global AGENTS.md.
argument-hint: "[workflow purpose]"
license: Apache-2.0
compatibility: actionlint and zizmor optional for validation
metadata:
  version: "2.0.0"
  category: generator
  related: dockerfile-generator release-retrigger rust-bump-rerelease
allowed-tools: Bash(actionlint *) Bash(zizmor *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# GitHub Actions

Pinned runner labels and the four binary targets are global policy (AGENTS.md); generic hardening (least-privilege `permissions`, untrusted input through `env`, pinned action versions) applies without restating it. Comments follow the global Code Comments rule.

## Release Pipeline Conventions

- A `detect` job reads the version from the artifact itself (Dockerfile `org.opencontainers.image.version`, `Chart.yaml` `version`) and skips versions already published
- `workflow_dispatch` inputs: `project` (or `chart`) as a `choice` list that is the source of truth, plus `force` (boolean) to rebuild and overwrite an existing version
- Re-releases use `force`, never package deletion
- Gate order: fmt, lint, test, coverage threshold, then build and push; a failed gate skips the push
- Native arm64 runners build arm64; no QEMU emulation for compilation
- Rust cross builds use cargo-zigbuild pinned to 0.23.0 or later (rustc 1.98+ passes an aarch64 linker flag older versions reject)
- Images and OCI charts publish to GHCR under the repo owner; multi-arch manifest list for containers
- One shared reusable workflow per artifact type (`_release-<type>.yml`) instead of a workflow per project

## Validation

- `actionlint` passes
- `zizmor` reports no high findings when available
- Dispatch inputs in the workflow match the projects that actually exist in the repo
