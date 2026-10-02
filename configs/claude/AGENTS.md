# Global Claude Code Policy

## Git Commit Signing

GPG signing is enforced globally via `git config --global commit.gpgsign true` (no `-S` needed).

For repositories hosted on github.com (check the git remote URL), always add DCO sign-off with `-s`:

```
git commit -s -m "..."
```

Applies to amends (`git commit --amend -s`) and cherry-picks (`git cherry-pick -s`). Prevents DCO check failures on OSS PRs.

## Code Comments

Always-on ground rule for every file Claude writes or edits: application code, Helm charts and values, Kubernetes manifests, Terraform and Terragrunt, Dockerfiles, workflows, scripts, config files, and command snippets shown in chat.

- Default to no comment. Add one only when the code cannot say it: a non-obvious constraint, a workaround with its cause, or a format the tooling requires (helm-docs `# --`, doc comments on public APIs, lint directives)
- Never narrate what the next line does, restate a key or function name, or log the change history ("added for X", "changed from Y")
- Background, rationale, and references belong in the commit message or MR body, not in code
- Never edit or delete existing comments, upstream originals included, unless asked; this rule governs only what Claude adds
- When editing a file, match its existing comment density rather than raising it
- Required comments are one short line, no em dash, no Kubernetes or tool version notes

## GitHub Actions Conventions

- Runner labels pin an explicit OS version (`ubuntu-26.04`, `ubuntu-26.04-arm`, `macos-26`); `-latest` silently changes the OS and breaks reproducibility.
- Binary releases build all four targets: `x86_64-unknown-linux-gnu` (ubuntu-26.04), `aarch64-unknown-linux-gnu` (ubuntu-26.04-arm) and `x86_64-apple-darwin`, `aarch64-apple-darwin` (macos-26). Container images build `linux/amd64` + `linux/arm64`.

## Skills Security Policy

This dotfiles repo is public on GitHub. Follow these rules when creating or modifying skills files.

### Prohibited Items

- Internal IP ranges and CIDRs (e.g., actual private network ranges like `10.20.30.0/24`)
- Company domains and hostnames (e.g., `*.company-internal.io`, `api.corp.com`)
- Company-specific naming patterns (e.g., `corp_worker`, `internal_` prefixes)
- API keys, tokens, passwords (actual credentials)
- Real AWS account IDs and ARNs (e.g., `111122223333`)
- Personal info (real emails, names, Slack IDs)

### Allowed Example Values

| Item | Value |
|------|-------|
| Domain | `example.com` |
| IP | `10.0.0.0/16` |
| AWS Account | `123456789012` |
| Secret | `${SECRET_NAME}` |

## Skills Authoring Guidelines

Skills are **declarative**: describe what the output must satisfy, not how to build it.

### Core Principle

Omit general knowledge Claude already knows. Keep only **your conventions and constraints**.

| Include | Exclude |
|---------|---------|
| Team/personal conventions (e.g., omit CPU limits) | General knowledge Claude already has (e.g., bash syntax) |
| Domain reference pattern tables (e.g., PromQL queries) | Full boilerplate templates |
| Non-obvious Good/Bad examples | Step-by-step procedures |

### Rules

- State constraints ("image versions pinned"), not procedures ("Step 1: pin the image")
- Keep under 100 lines; Claude generates boilerplate contextually
- Use tables for pattern references instead of repetitive code blocks
- List validation criteria, not numbered step sequences

### Structure

1. **Frontmatter** — `name`, `description`
2. **Output Requirements** — Constraints the output must satisfy
3. **Reference** — Minimal examples clarifying constraints
4. **Validation** — Commands or criteria to verify output quality
