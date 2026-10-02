---
name: release-retrigger
description: Re-publish a release at the same version, either by force-dispatching the release workflow or by cycling the git tag with its release and package.
when_to_use: Re-releasing, re-tagging, cycling a release tag, or re-triggering a release pipeline, e.g. "재릴리즈", "0.1.0으로 재릴리즈", "커밋 푸시후 재릴리즈", "태그 다시 찍고 릴리즈". Not for Rust toolchain bumps (use rust-bump-rerelease) or post-release mirroring (use release-promote).
argument-hint: "<tag or version>"
license: Apache-2.0
compatibility: gh CLI authenticated with push and package access
metadata:
  version: "2.0.0"
  category: action
  related: rust-bump-rerelease release-promote git-ship done-check
allowed-tools: Bash(git *) Bash(gh *) Read Grep
user-invocable: true
disable-model-invocation: false
---

# Release Retrigger

## Constraints

- Same version, always: never bump Dockerfile labels, `Cargo.toml`, or `Chart.yaml` unless the user names a new version
- Version comes from the user or the existing tag; never auto-increment
- Tag format and commit format come from the repo `AGENTS.md` (e.g. `kuo/0.2.0`, `backstage/1.48.5-1`, `grafana-dashboards/charts/1.0.0`)
- Runs end to end without confirmation pauses once invoked
- Uncommitted changes are committed and pushed first via git-ship rules; push denied means print the command for the user and continue after
- Never force-push branches

## Path Selection

| Release trigger | Re-release path |
|-----------------|-----------------|
| Workflow has a `force` dispatch input | `gh workflow run <wf> -f project=<name> -f force=true` (charts: `-f chart=<name>`); no deletion |
| Tag push triggers the workflow | Delete local tag, remote tag, GitHub Release, and the GHCR version for that tag, then re-tag `HEAD` and push the tag |
| Both image and chart changed | Re-release each artifact; they are separate runs |

- Cleanup commands are independent and run in parallel with errors suppressed for missing items
- GHCR refuses to delete the last tagged version of a package; never delete the whole package (it resets visibility), switch to the force path or report

## GHCR Reference

| Tag | Package | Image tag |
|-----|---------|-----------|
| `kuo/0.2.0` | `kuo` | `0.2.0` |
| `grafana-dashboards/charts/1.2.0` | `charts%2Fgrafana-dashboards` | `1.2.0` |

Version id lookup: `gh api /user/packages/container/<package>/versions --jq '.[] | select(.metadata.container.tags[] == "<tag>") | .id'`; org-owned packages use `/orgs/<org>/`.

## Validation

- `git ls-remote --tags origin <tag>` points at `HEAD` (tag path)
- The triggered run is found with `gh run list` and its build job took the rebuild path
- Report the run URL; follow-up status checks belong to release-promote
