# Global Claude Code Policy

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
