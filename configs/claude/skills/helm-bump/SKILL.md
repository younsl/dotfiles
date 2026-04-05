---
name: helm-bump
description: Bump Helm chart versions (Chart.yaml appVersion/version, values.yaml image tags). Use when updating, upgrading, or bumping chart or app versions.
allowed-tools: Bash, Read, Edit, Glob, Grep
---

# Helm Chart Version Bump

## Constraints

- **Wrapper chart pattern** — if the chart is a wrapper chart (minimal templates, upstream chart as dependency, values-only override), bump `dependencies[].version` and sync `appVersion` to match the upstream chart's `appVersion`; never vendor or modify upstream templates
- **Verify version exists before editing** — query the registry first; if the version is not found, abort and show the latest available version
- **Preserve all YAML comments** — never strip, rewrite, or reorder comments in `values.yaml` or `Chart.yaml`
- **Preserve key order** — do not alphabetize or reformat; edit only the target value in place
- **Touch nothing unrelated** — no refactoring, cleanup, or "improvements" beyond the requested bump
- **Multi-environment overrides** — if environment-specific value files or directories exist, preserve their overrides; never collapse them to a single default

## Commit Message Template

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

- Bumped version matches a real, published version in the upstream registry
- `git diff` shows only version-related line changes — no unrelated modifications
