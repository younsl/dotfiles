# Claude Code Skills

Custom skills for DevOps workflows. Each skill is a declarative prompt template that Claude Code loads on invocation.

## Available Skills

| Skill | Type | Description |
|-------|------|-------------|
| `bash-generator` | Generator | Production-ready Bash scripts |
| `dockerfile-generator` | Generator | Optimized, secure Dockerfiles |
| `github-actions-generator` | Generator | GitHub Actions workflow files |
| `helm-generator` | Generator | Helm charts with secure defaults |
| `k8s-generator` | Generator | Kubernetes manifests (EKS-optimized) |
| `rust-generator` | Generator | Rust applications and CLI tools |
| `terraform-generator` | Generator | Terraform configurations (AWS) |
| `promql-generator` | Generator | PromQL queries, alerting rules, SLO/SLIs |
| `helm-validator` | Validator | Helm chart review and audit |
| `k8s-validator` | Validator | Kubernetes manifest review and audit |

## Usage

Skills are invoked automatically when Claude Code matches a task to a skill description, or manually via slash command:

```
/bash-generator
/k8s-validator
```

## Setup

Symlink the skills directory to `~/.claude/skills/`:

```bash
ln -sf /path/to/dotfiles/configs/claude/skills ~/.claude/skills
```

## Authoring

Skills are **declarative** — they define output constraints, not step-by-step procedures. See the [Skills Authoring Guidelines](../CLAUDE.md#skills-authoring-guidelines) in CLAUDE.md.

Each `SKILL.md` follows this structure:

```
Frontmatter         → name, description (triggers skill matching)
Output Requirements → Constraints the output must satisfy
Reference           → Minimal examples clarifying constraints
Validation          → Commands or criteria to verify output
```

Keep skills under 100 lines. Omit general knowledge Claude already has; include only your conventions and constraints.
