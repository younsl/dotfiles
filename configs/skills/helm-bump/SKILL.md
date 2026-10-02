---
name: helm-bump
description: Bump Helm chart versions (Chart.yaml appVersion/version, dependency versions, values.yaml image tags) after verifying the target version exists.
when_to_use: Updating, upgrading, or bumping chart or app versions, e.g. "차트 버전 업그레이드", "업스트림 최신 버전으로 범프", "이미지 태그 변경".
argument-hint: "[chart] [version]"
license: Apache-2.0
compatibility: helm, crane, gh, or aws CLI depending on registry type
metadata:
  version: "1.1.0"
  category: action
  related: helm-chart release-promote git-ship
allowed-tools: Bash(helm *) Bash(crane *) Bash(gh api *) Bash(aws ecr *) Bash(git *) Read Edit Glob Grep
user-invocable: true
disable-model-invocation: false
---

# Helm Chart Version Bump

## Constraints

- **Wrapper chart pattern**: if the chart is a wrapper chart (minimal templates, upstream chart as dependency, values-only override), bump `dependencies[].version` and sync `appVersion` to match the upstream chart's `appVersion`; never vendor or modify upstream templates
- **Verify version exists before editing**: query the registry first; if the version is not found, abort and show the latest available version
- **Preserve all YAML comments**: never strip, rewrite, or reorder comments in `values.yaml` or `Chart.yaml`
- **Preserve key order**: do not alphabetize or reformat; edit only the target value in place
- **Touch nothing unrelated**: no refactoring, cleanup, or "improvements" beyond the requested bump
- **Multi-environment overrides**: if environment-specific value files or directories exist, preserve their overrides; never collapse them to a single default; "전환경" means every environment directory
- **Upstream values sync**: when the upstream values structure changed between versions, carry the new structure into the wrapper values with upstream comments verbatim, then re-apply local overrides; never rewrite upstream helm-docs comments
- **Image-only bump**: change `appVersion` and the explicit image tag override; leave chart `version` unchanged unless the chart itself changed
- **Unset with null**: removing an upstream default needs an explicit `null`; deleting the key does nothing under map merge

## Commit Message Template

MR title and body follow git-ship (Korean title after the prefix for internal repos).

```
bump(<chart>): Upgrade <chart> from <old version> to <new version>

* Bump <component> from <old version> to <new version>
* Source: <upstream release URL or registry>
```

## Version Verification Reference

| Registry Type | Verify Specific Version | List Available Versions |
|---------------|------------------------|------------------------|
| Helm repo | `helm search repo <chart> --version <ver>` | `helm search repo <chart> --versions` |
| OCI | `helm show chart oci://<reg>/<chart> --version <ver>` | `crane ls <reg>/<chart>` |
| GHCR | `helm show chart oci://ghcr.io/<owner>/<chart> --version <ver>` | `gh api /user/packages/container/<pkg>/versions` |
| ECR | `helm show chart oci://<acct>.dkr.ecr.<region>.amazonaws.com/<chart> --version <ver>` | `aws ecr describe-images --repository-name <chart>` |

## Validation

- Wrapper chart: `helm show values <chart> --version <new>` diffed against the dependency block leaves only intended overrides
- Bumped version matches a real, published version in the upstream registry
- `git diff` shows only version-related line changes: no unrelated modifications
