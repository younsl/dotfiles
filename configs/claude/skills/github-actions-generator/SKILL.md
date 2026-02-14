---
name: github-actions-generator
description: Generate GitHub Actions workflow files. Use when creating or modifying CI/CD pipelines, .github/workflows/ YAML files, or GitHub Actions configurations.
---

# GitHub Actions Workflow Generator

Generate GitHub Actions workflows following best practices.

## Output Requirements

- Runner labels use explicit OS versions (never `-latest` suffix)
- Action versions pinned to major version tags (e.g., `actions/checkout@v6`)
- Job-level `permissions` declared with least privilege
- Untrusted input (`github.event.*`) passed via `env:` block, never directly interpolated in `run:`
- Multi-line commit messages use HEREDOC format

## Runner Version Convention

```yaml
# Correct
runs-on: ubuntu-24.04
runs-on: macos-26

# Incorrect (silently changes OS, breaks reproducibility)
runs-on: ubuntu-latest
```

## Multi-Platform Build Requirements

**Binary releases** include all four target combinations:

| OS | Target | Platform/Arch |
|----|--------|---------------|
| ubuntu-24.04 | x86_64-unknown-linux-gnu | linux/amd64 |
| ubuntu-24.04 | aarch64-unknown-linux-gnu | linux/arm64 |
| macos-26 | x86_64-apple-darwin | darwin/amd64 |
| macos-26 | aarch64-apple-darwin | darwin/arm64 |

**Container images** support `linux/amd64` and `linux/arm64` via `docker/build-push-action`.

## Security Constraints

```yaml
# Untrusted input must use env indirection
env:
  PR_TITLE: ${{ github.event.pull_request.title }}
run: echo "$PR_TITLE"
```

## HEREDOC Commit Messages

```yaml
run: |
  git commit -m "$(cat <<'EOF'
  Commit message here.
  EOF
  )"
```
