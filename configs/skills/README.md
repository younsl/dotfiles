# Skills

Custom Claude Code skills for DevOps workflows, written to the [Agent Skills](https://agentskills.io) format: one directory per skill holding a `SKILL.md` with `name` and `description` frontmatter.

## Available Skills

| Skill | Type | Description |
|-------|------|-------------|
| `airflow-dag-generator` | Generator | Airflow DAGs (parse cost, idempotency) |
| `bash-generator` | Generator | Production-ready Bash scripts |
| `dockerfile-generator` | Generator | Optimized, secure Dockerfiles |
| `falco-rules` | Generator | Falco custom rules, exceptions, and override syntax |
| `github-actions-generator` | Generator | GitHub Actions workflow files |
| `helm-bump` | Action | Bump Helm chart versions and image tags |
| `helm-generator` | Generator | Helm charts with secure defaults |
| `helm-validator` | Validator | Helm chart review and audit |
| `k8s-generator` | Generator | Kubernetes manifests (EKS-optimized) |
| `k8s-validator` | Validator | Kubernetes manifest review and audit |
| `promql-generator` | Generator | PromQL queries, alerting rules, SLO/SLIs |
| `release-retrigger` | Action | Re-trigger release by cycling a semver tag |
| `rust-bump-rerelease` | Action | Bump Rust toolchain and re-release container image |
| `rust-generator` | Generator | Rust applications and CLI tools |
| `terraform-generator` | Generator | Terraform configurations (AWS) |

## Usage

Claude Code picks a skill automatically when a task matches its description. Invoke one explicitly with `/helm-bump`.

## Setup

The bootstrap script links each skill directory into `~/.claude/skills/<skill>`.

Links are created per skill rather than for the whole directory, so entries Claude Code manages itself (`synced/`, skills installed with `npx skills` or `gh skill`) stay in `~/.claude/skills/` and out of this repository.

```bash
./scripts/bootstrap/bootstrap-dotfiles.sh
```

## Layout

```
<skill>/
├── SKILL.md              # Required. Frontmatter + constraints
└── evals/                # Optional. Skill eval cases
```

## Authoring

Skills are declarative. They state the constraints the output must satisfy, not step-by-step procedures. See the Skills Authoring Guidelines in [`../claude/AGENTS.md`](../claude/AGENTS.md).

Each `SKILL.md` follows this structure:

```
Frontmatter         -> name, description (drives skill matching)
Output Requirements -> Constraints the output must satisfy
Reference           -> Minimal examples clarifying constraints
Validation          -> Commands or criteria to verify output
```

Keep skills under 100 lines. Omit general knowledge the model already has and keep only your conventions and constraints.
