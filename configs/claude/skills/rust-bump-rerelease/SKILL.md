---
name: rust-bump-rerelease
description: Bump a Rust project's toolchain version (rust-version / MSRV) and re-release its container image at the same version.
when_to_use: Whenever asked to bump, upgrade, or update the Rust version, toolchain, or MSRV of a Rust tool, even without the words "re-release", e.g. "rust 버전 1.100.0으로 bump 후 재릴리즈". Not for re-tagging without a Rust change (use release-retrigger), chart bumps (use helm-bump), post-release mirroring (use release-promote), or crate dependency bumps.
argument-hint: "<project> <rust-version>"
license: Apache-2.0
compatibility: gh CLI authenticated, rustup with the target toolchain; repo with _release-rust-scratch-containers.yml workflow
metadata:
  version: "1.2.0"
  category: action
  related: release-retrigger helm-bump release-promote git-ship done-check
allowed-tools: Bash(git *) Bash(gh *) Bash(cargo *) Bash(curl -s -o /dev/null *) Read Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Rust Version Bump + Re-release

Bump the Rust toolchain version, update docs, then re-release the named projects at the **same** artifact version.

## Critical: this is a toolchain bump, NOT a version release

The whole point of a *re-release* is that the artifact version is **identical**: only the Rust toolchain changes. **Never bump any of these** while doing this task:

| Must stay unchanged | Where |
|---------------------|-------|
| Container image version | Dockerfile `org.opencontainers.image.version` label (the `detect` job keys off it) |
| Cargo package version | `Cargo.toml` `version` (the `version =` line, **not** `rust-version`) |
| Helm chart + app version | `charts/*/Chart.yaml` `version` and `appVersion` |

If a request also wants a real version bump, that is a separate `helm-bump` / release task: do not fold it in here.

## Target version

- Must be newer than the current `rust-version`. Equal or older: stop and report with no edits. Equal means nothing to bump, a same-version rebuild belongs to release-retrigger.
- Must be a published stable release: `curl -s -o /dev/null -w '%{http_code}' https://static.rust-lang.org/dist/channel-rust-<x.y.z>.toml` returns `200`, else stop and report.

## Scope

- Rust crates under `box/addons/` (containers) and `box/cli/` (`ij`, `vlt`). List them with `grep -rn '^rust-version' box --include=Cargo.toml --exclude-dir=target`.
- Every crate and toolchain pin shares one version. When the pins are older than the target, the bump is repo-wide: confirm the widened scope with the user before editing, then move every crate and pin in one commit. When the pins already sit at the target, only the lagging crates named in the request move.
- Re-release only the projects the user named.

## Bump: files to update

| File | Target | Note |
|------|--------|------|
| `Cargo.toml` | `rust-version = "x.y.z"` | Normalize to full semver even if it was minor-only (`"1.95"` → `"1.96.0"`) |
| `README.md` | shields.io Rust badge `rust-x.y.z`, prose like `Rust x.y.z` | prose only if present |
| project `AGENTS.md`, `docs/development.md`, `docs/metrics.md` | toolchain mentions | only if present |
| root `README.md` | `x.y+` link to the release tag | repo-wide bumps |
| `.github/workflows/_release-rust-scratch-containers.yml` | `build-binaries` `toolchain:` | `test` job uses `@stable`, no edit |
| `.github/workflows/release-harbor-arm64.yml` | both `toolchain:` pins | |
| `.github/workflows/ci-forklift.yml` | `env.RUST_VERSION` | |
| `box/addons/forklift/rust-toolchain.toml` | `channel` | |

- `_release-rust-cli.yml` uses `@stable` unpinned: no edit.
- CHANGELOG entries, `docs/designs/`, `docs/testing/`, and example strings in code or tests record history: leave them.
- New clippy lints on the target toolchain are fixed in the same commit, since the release `test` job runs `cargo clippy -- -D warnings` on stable. These are the only code changes allowed, each named in the commit body.

## Commit

Message: `[repo] chore(deps): bump Rust to x.y.z` when the shared pins move, `[<project>] chore(deps): bump Rust to x.y.z` when only lagging crates move. Commit to `main` per repo `AGENTS.md`, pathspec and push rules from git-ship. Pushing to `main` may require user authorization: if denied, ask the user to run the push, then continue.

## Re-release (same version)

The `detect` job skips any version already published, and a Rust bump leaves that version unchanged, so a plain push won't trigger a build. Dispatch with `force=true` to overwrite the existing artifact. Never delete from GHCR: it refuses to delete the last tagged version, and deleting the package resets visibility.

| Project | Command |
|---------|---------|
| Scratch containers | `gh workflow run _release-rust-scratch-containers.yml -f project=<project> -f force=true` |
| `harbor` | `gh workflow run release-harbor-arm64.yml -f force=true` |
| `ij` | `gh workflow run _release-rust-cli.yml -f project=ij -f force=true` |
| `vlt` | no release workflow: bump + commit only |

Dispatch one command per project: a shell loop over `gh workflow run` may be denied where single dispatches pass.

`workflow_dispatch` `project` choices are the authoritative list: read them from the `options:` block of the workflow rather than trusting any list written here. The choice value is the GHCR package name under `younsl/`, mapped to its source dir in `.github/scripts/ci-rust-projects.json` (`kuo` is `kubernetes-upgrade-operator`).

## Validation

- No current-state mention of the old version remains, exact or minor-only: `grep -rnE "<old>\.[0-9]+|[Rr]ust[ -]<old>([^.0-9]|$)|<old> toolchain|<old>\+" box .github README.md --include='*.toml' --include='*.md' --include='*.yml' --exclude=Cargo.lock --exclude=CHANGELOG.md --exclude-dir=target --exclude-dir=node_modules --exclude-dir=designs --exclude-dir=testing --exclude-dir=skills` with `<old>` as the escaped old minor (`1\.99`) returns nothing.
- `git diff` changes no Dockerfile image label, `Cargo.toml` `version`, or `Chart.yaml` `version`/`appVersion`. Code changes are limited to clippy fixes for the new toolchain.
- `cargo +<x.y.z> clippy -- -D warnings` passes in every crate whose `rust-version` moved.
- The `cargo-zigbuild` pin in `_release-rust-scratch-containers.yml` stays >= 0.23.0 (rustc 1.98+ aarch64 linker arg).
- `gh run view <id> --json jobs`: `detect` succeeds and spawns `test (<project>, ...)`, confirming the forced rebuild path was taken.
