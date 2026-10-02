---
name: rust-bump-rerelease
description: Bump a Rust project's toolchain version (rust-version / MSRV) and re-release its container image at the same version.
when_to_use: Whenever asked to bump, upgrade, or update the Rust version, toolchain, or MSRV of a Rust tool, even without the words "re-release", e.g. "rust 버전 1.96.0으로 bump 후 재릴리즈". Not for re-tagging without a Rust change (use release-retrigger), chart bumps (use helm-bump), or crate dependency bumps.
argument-hint: "<project> <rust-version>"
license: Apache-2.0
compatibility: gh CLI authenticated; repo with _release-rust-scratch-containers.yml workflow
metadata:
  version: "1.1.0"
  category: action
  related: release-retrigger helm-bump done-check
allowed-tools: Bash(git *) Bash(gh *) Read Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Rust Version Bump + Re-release

Bump a project's Rust version, update docs, then re-release its container image at the **same** image version.

## Critical: this is a toolchain bump, NOT a version release

The whole point of a *re-release* is that the artifact version is **identical**: only the Rust toolchain changes. **Never bump any of these** while doing this task:

| Must stay unchanged | Where | Why |
|---------------------|-------|-----|
| Container image version | Dockerfile `org.opencontainers.image.version` label | The `detect` job keys off this; changing it makes a new release, not a re-release, and breaks the delete-then-rebuild flow |
| Cargo package version | `Cargo.toml` `version` (the `version =` line, **not** `rust-version`) | Crate/release version is independent of the toolchain bump |
| Helm chart + app version | `charts/*/Chart.yaml` `version` and `appVersion` | The chart still points at the same image tag; bumping it would ship a phantom release |

Only `rust-version` (and the doc mentions of it) change. If a request also wants a real version bump, that is a separate `helm-bump` / release task: do not fold it in here.

## Scope

- Rust projects under `box/kubernetes/` and `box/tools/`.
- The container re-release applies only to projects with a `Dockerfile` released by `.github/workflows/_release-rust-scratch-containers.yml`. CLI-only tools (no Dockerfile, e.g. `ij`, `vlt`) get the bump + commit only: optionally a tagged CLI release via the `release-retrigger` skill.

## Bump: files to update

Update every occurrence of the old version, then grep to confirm none remain.

| File | Target | Note |
|------|--------|------|
| `Cargo.toml` | `rust-version = "x.y.z"` | Normalize to full semver even if it was minor-only (`"1.95"` → `"1.96.0"`) |
| `README.md` | shields.io Rust badge `rust-x.y.z` | |
| `README.md` | prose like `Rust x.y.z (edition 2024)` | only if present |
| project-local `AGENTS.md` | toolchain note `Rust **x.y.z** toolchain` | only if present |

The `build-binaries` job in `_release-rust-scratch-containers.yml` pins an explicit `toolchain:` version: bump it to the new version too. The `test` job uses `dtolnay/rust-toolchain@stable` and needs no edit.

aarch64 trap: rustc 1.98+ passes `--fix-cortex-a53-843419` to the linker for aarch64-linux targets. cargo-zigbuild must be >= 0.23.0 or the aarch64 build fails with `error: unsupported linker arg`. The pin and its rationale live next to the `Install cargo-zigbuild` step in the workflow.

Validation:
- `grep -rn "<old-version>" <project-dir> --include="*.toml" --include="*.md" --include="Dockerfile"` returns nothing (catch any other Rust-version mention too, e.g. an out-of-sync `Rust 1.94.1+` prerequisite line).
- `git diff` touches only `rust-version` and doc mentions: confirm it does **not** change the Dockerfile image label, `Cargo.toml` `version`, or `Chart.yaml` `version`/`appVersion`.

## Commit

Message: `[<project>] chore(deps): bump Rust to x.y.z`. Push to the current branch (`main`). Pushing to `main` may require user authorization: if denied, ask the user to run the push, then continue.

## Re-release (same image version)

The `detect` job reads the Dockerfile `org.opencontainers.image.version` label and skips any version already on GHCR. A Rust bump leaves that label unchanged, so a plain push won't trigger a build: dispatch with `force=true` to overwrite the existing tag (never delete from GHCR; it refuses to delete the last tagged version, and deleting the package resets visibility):

```bash
gh workflow run _release-rust-scratch-containers.yml -f project=<project> -f force=true
```

Dispatch one command per project: a shell loop over `gh workflow run` may be denied where single dispatches pass.

Verify: `gh run view <id> --json jobs`: `detect` succeeds and spawns `test (<project>, ...)`, confirming the forced rebuild path was taken.

## Project values

`workflow_dispatch` `project` choices are the authoritative list: read them from the `options:` block at the top of `_release-rust-scratch-containers.yml` rather than trusting any list written here. The choice value is the GHCR package name under `younsl/`; `kuo`'s source dir is `kubernetes-upgrade-operator`.
