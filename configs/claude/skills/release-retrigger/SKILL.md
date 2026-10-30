---
name: release-retrigger
description: Re-publish a release at the same version, either by force-dispatching the release workflow or by cycling the git tag with its release and package.
when_to_use: Re-releasing, re-tagging, cycling a release tag, or re-triggering a release pipeline, e.g. "재릴리즈", "0.1.0으로 재릴리즈", "커밋 푸시후 재릴리즈", "태그 다시 찍고 릴리즈". Not for Rust toolchain bumps (use rust-bump-rerelease), post-release mirroring (use release-promote), or shipping a new version (use helm-bump or git-ship).
argument-hint: "<tag or version>"
license: Apache-2.0
compatibility: gh CLI authenticated with push and package access, crane for registry lookups
metadata:
  version: "2.1.0"
  category: action
  related: rust-bump-rerelease release-promote git-ship done-check
allowed-tools: Bash(git *) Bash(gh *) Bash(crane ls *) Bash(crane digest *) Bash(cargo llvm-cov *) Read Grep
user-invocable: true
disable-model-invocation: false
---

# Release Retrigger

## Constraints

- Same version, always: never bump Dockerfile labels, `Cargo.toml`, or `Chart.yaml`
- Version comes from the user, else the current version file or existing tag; never auto-increment
- The requested version must equal an existing artifact (registry tag or git tag) and the version the release ref builds. Otherwise stop and report, never rebuild a different version
- Tag format and commit format come from the repo `AGENTS.md` (e.g. `<component>/<semver>`, `<chart>/charts/<semver>`). An `AGENTS.md` saying releases are not tag-based means the force path
- Runs end to end without confirmation pauses once invoked, except a version mismatch or a barred tag path, which end the run with a report
- Uncommitted changes and unpushed commits ship first via git-ship rules, so the release ref is on a remote branch
- Repo release gates (e.g. addons 70% `cargo llvm-cov` line coverage) pass before dispatch, force re-releases included
- Never force-push branches

## Path Selection

| Release trigger | Re-release path |
|-----------------|-----------------|
| Workflow has a `force` dispatch input | `gh workflow run <wf> -f <input>=<choice> -f force=true`, input name and choice value read from the workflow's `workflow_dispatch` block (e.g. `project=kuo`, `container=backstage`, `chart=<chart>`, harbor has only `force`); no deletion |
| Tag push triggers the workflow | Delete local tag, remote tag, GitHub Release, and the GHCR version for that tag, then re-tag `HEAD` and push the tag |

- The choice value is the release name, not the directory (addons: `kuo` for `kubernetes-upgrade-operator`, mapped in `.github/scripts/ci-rust-projects.json`)
- Tag path only where the repo `AGENTS.md` allows deleting registry artifacts, otherwise force path or report
- Cleanup commands are independent and run in parallel with errors suppressed for missing items
- GHCR refuses to delete the last tagged version of a package; never delete the whole package (it resets visibility), switch to the force path or report

## GHCR Reference

| Tag | Package | Image tag |
|-----|---------|-----------|
| `myapp/1.0.0` | `myapp` | `1.0.0` |
| `mychart/charts/1.2.0` | `charts%2Fmychart` | `1.2.0` |

Version id lookup: `gh api /user/packages/container/<package>/versions --jq '.[] | select(.metadata.container.tags[] == "<tag>") | .id'`; org-owned packages use `/orgs/<org>/`.

## Validation

- `git ls-remote --tags origin <tag>` points at `HEAD` (tag path)
- The triggered run is found with `gh run list` and its detect log shows the forced rebuild line (addons: `exists on GHCR, forced rebuild`)
- Report the run URL; follow-up status checks belong to release-promote
