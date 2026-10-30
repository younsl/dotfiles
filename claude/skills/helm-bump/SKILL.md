---
name: helm-bump
description: Bump Helm chart versions (Chart.yaml appVersion/version, dependency versions, values.yaml image tags) after verifying the target version exists, then ship the change as a commit and MR/PR with the upstream release notes attached.
when_to_use: Updating, upgrading, or bumping chart or app versions, with or without an MR, e.g. "차트 버전 업그레이드", "업스트림 최신 버전으로 범프", "이미지 태그 변경", "전환경 차트 범프 진행", "범프하고 MR 올려줘", "CVE 패치를 위해 차트 범프". Not for chart authoring or new values keys (use helm-chart), post-release mirror and consumer chart bumps of a first-party release (use release-promote), Rust toolchain re-releases (use rust-bump-rerelease), or shipping changes that are not a version bump (use git-ship).
argument-hint: "[chart] [version] [purpose]"
license: Apache-2.0
compatibility: helm and crane, or aws CLI for ECR; git plus glab (GitLab) or gh (GitHub) for shipping
metadata:
  version: "1.4.0"
  category: action
  related: helm-chart release-promote git-ship writing-style
allowed-tools: Bash(helm *) Bash(crane *) Bash(aws ecr *) Bash(git *) Bash(glab *) Bash(gh *) Read Edit Glob Grep
user-invocable: true
disable-model-invocation: false
---

# Helm Chart Version Bump

One request runs end to end: verify the version, edit, validate, then ship as a commit and MR/PR whose description carries the upstream release notes.

## Bump Constraints

- **Wrapper chart pattern**: if the chart is a wrapper chart (minimal templates, upstream chart as dependency, values-only override), bump `dependencies[].version`, sync `appVersion` to the upstream chart's `appVersion`, and handle the wrapper `version` the way the repo's past bumps did: mirror the upstream chart version if it already tracks it, leave it as is if it stayed fixed across earlier bumps, else minor; never vendor or modify upstream templates
- **Verify version exists before editing**: query the registry first; if the version is not found, abort with no edits, no commit, no MR, and show the latest available version
- **Edit in place only**: change only what the bump requires; no comment edits, reorder, reformat, or unrelated cleanup
- **Chart.lock**: if tracked, regenerate it with `helm dependency update` in the same change; leave `charts/*.tgz` out
- **Multi-environment overrides**: if environment-specific value files or directories exist, preserve their overrides; never collapse them to a single default; "전환경" means every environment directory, and each one with its own `Chart.yaml` gets the same bump
- **Upstream values sync**: wrapper values are the full upstream copy (helm-chart); diff upstream `helm show values` between the old and new chart versions and carry every hunk over, placing new keys at their upstream position with comments verbatim, then re-apply local overrides; never rewrite upstream helm-docs comments
- **Image repositories in new keys**: when the repo rewrites images to a registry proxy (repo AGENTS.md), new upstream image keys get the same rewrite even if the component is disabled; tags stay upstream
- **Pinned image tags follow the dependency**: an explicit image tag override equal to the old `appVersion` (or to the old upstream default tag) moves to the new value in the same change, after verifying that tag exists in the registry the values point at; otherwise the dependency bump renders the old image
- **Image-only bump**: change `appVersion` and the explicit image tag override; leave chart `version` unchanged unless the chart itself changed
- **Unset with null**: removing an upstream default needs an explicit `null`; deleting the key does nothing under map merge
- **Repo version inventory follows the bump**: when the repo keeps a document listing chart and app versions (e.g. a README table), update the bumped chart's row in the same commit so the inventory never lags the charts
- **Stated purpose is verified, not assumed**: when the request names a goal such as a CVE fix, confirm the new release actually delivers it (e.g. Go version of the shipped binaries, fixed dependency) and state any part it does not cover; a bump that does not deliver the goal is reported instead of shipped

## Ship Constraints

Shipping follows the `git-ship` skill (load it) for branch policy, pathspec commit, sign-off, push, and MR/PR body conventions; this section only adds what is specific to a bump.

- Default scope is the full ship: new branch from the default branch, commit, push with upstream tracking, MR/PR. Stop earlier only when the request says so ("커밋만", "편집만", "MR 은 내가 올릴게") or when validation fails
- The commit holds only the bumped chart paths and the inventory row; unrelated working tree changes stay uncommitted
- Branch name `bump/<chart>-<new version>` for a plain update; `fix/<chart>-<topic>` when the bump is the means to a fix
- Title and commit subject lead with the purpose when the bump is a means (`fix(<chart>): <envs> <goal>을 위해 <version> 적용`); plain updates keep `bump(<chart>): ...` or the repo's own convention from `git log`
- MR/PR body stays short (`git-ship` length rules) and ends with exactly one release notes `<details>` block (see Release Notes)
- Final report: branch, commit subject, full MR/PR URL, plus any part of the stated purpose the bump does not cover

## Release Notes

- Source: every upstream release strictly after the old version up to and including the new one, patch releases included; GitHub releases for monorepo charts are tagged `<chart>-<version>` (`gh release view <tag> -R <owner>/<repo>`), else the chart's `artifacthub.io/changes` annotation from `helm show chart`, else the upstream CHANGELOG
- One `<details><summary>릴리즈 노트</summary>` block for the whole MR, summarized in the language of the MR body
- Inside it, one bold `**<version>**` subheading per release in the range, oldest first, so reviewers can see which release brought which change
- Bullets under each version start with a meaning prefix (operator/app, 이미지, 서브차트, 신규 옵션, 수정); renovate dependency tables become the 이미지 and 서브차트 bullets
- A release whose entries are all dropped by the filter below keeps its subheading with a single `- 이 차트 변경 없음` bullet, so the range stays visibly complete
- Drop CI, docs, release tooling, first-contribution lines, and entries for sibling charts in the same monorepo
- PR references as plain `(#1234)` text; no links to release pages, tags, or github.com
- When environments start from different old versions, list every release from the oldest start and append the environments a release applies to when it is not all of them, e.g. `**92.12.0** (dev, stg)`

```markdown
<details><summary>릴리즈 노트</summary>

**92.12.0**

- 신규 옵션: ServiceMonitor 별 `serviceMonitor.scrapeClass` 추가 (#7337)

**92.13.0**

- 신규 옵션: admission webhook 인증서 Secret 을 `kubernetes.io/tls` 로 생성하는 `secretType` 추가 (#7373)

**92.14.0**

- operator: prometheus-operator v0.94.1 에서 v0.94.2 로 변경 (#7435)
- 이미지: prometheus v3.15.1 (#7435)

</details>
```

## Commit Message

Subject follows the repo's `git log` convention (younsl/addons: `[<component>] chore(deps): bump <chart> to <new version>`). Body:

```
* Bump <component> from <old version> to <new version> (<environments>)
* <why, e.g. which binary or dependency carries the fix>
* Source: <upstream chart repository or registry>
```

## Version Verification Reference

| Registry Type | Verify Specific Version | List Available Versions |
|---------------|------------------------|------------------------|
| Helm repo | `helm show chart <chart> --repo <url> --version <ver>` | `helm show chart <chart> --repo <url>` (latest) |
| OCI | `helm show chart oci://<reg>/<chart> --version <ver>` | `crane ls <reg>/<chart>` |
| GHCR | `helm show chart oci://ghcr.io/<owner>/<chart> --version <ver>` | `crane ls ghcr.io/<owner>/<chart>` |
| ECR | `helm show chart oci://<acct>.dkr.ecr.<region>.amazonaws.com/<chart> --version <ver>` | `aws ecr describe-images --repository-name <chart>` |
| Container image | `crane digest <img>:<tag>` | `crane ls <img>` |

## Validation

- Wrapper chart: `helm show values <chart> --version <new>` diffed against the dependency block leaves only intended overrides
- Comment parity: every comment line in the new upstream values also appears in the local values, or was already missing before the bump
- `helm template` renders the new chart label and the new image tag, with no leftover old `appVersion` tag
- Bumped version matches a real, published version in the upstream registry
- `Chart.lock`, when tracked, lists the new dependency version
- `git diff` shows only version-related line changes: no unrelated modifications
- After shipping: `git rev-parse @{u}` equals `HEAD`, the MR/PR description contains exactly one release notes `<details>` block with a subheading for every release in the range
