# Skills

Custom Claude Code skills for DevOps workflows, written to the [Agent Skills](https://agentskills.io) format: one directory per skill holding a `SKILL.md` with `name` and `description` frontmatter.

## Available Skills

| Skill | Type | Description |
|-------|------|-------------|
| `airflow-dag-generator` | Generator | Airflow DAGs (parse cost, idempotency) |
| `bash-generator` | Generator | Production-ready Bash scripts |
| `done-check` | Validator | Verification gate and release readiness report |
| `dockerfile-generator` | Generator | Optimized, secure Dockerfiles |
| `falco-rules` | Generator | Falco custom rules, exceptions, and override syntax |
| `git-ship` | Action | Commit, push, branch, and open or update MR/PR |
| `github-actions-generator` | Generator | GitHub Actions workflow files |
| `helm-bump` | Action | Bump Helm chart versions and image tags |
| `helm-chart` | Generator | Author and review Helm charts and wrapper values |
| `jira-issue` | Action | Jira work items with team template via acli |
| `k8s-manifest` | Generator | Author and review Kubernetes manifests and CRDs |
| `promql-generator` | Generator | PromQL, alert rules, Grafana panels verified on live data |
| `release-promote` | Action | Release status, registry mirror, consumer chart bump |
| `release-retrigger` | Action | Re-publish a release at the same version |
| `rust-bump-rerelease` | Action | Bump Rust toolchain and re-release container image |
| `rust-generator` | Generator | Rust applications and CLI tools |
| `terraform-generator` | Generator | Terraform and Terragrunt for AWS |
| `writing-style` | Style | Writing rules for docs, MR, Jira, Confluence, Slack |

## Site Values

Action skills that touch company systems (`jira-issue`, `release-promote`) read site-specific values such as the Jira project key or internal registry host from environment variables set in `~/.zshrc.local`, which is not tracked. Each skill lists its variables.

## Usage

Claude Code picks a skill automatically when a task matches its description. Invoke one explicitly with `/helm-bump`.

Code comment policy is not a skill: it lives in the global [`AGENTS.md`](../claude/AGENTS.md) so it applies to every session, and code-writing skills point to it.

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
Frontmatter         -> Standard metadata block (drives skill matching)
Output Requirements -> Constraints the output must satisfy
Reference           -> Minimal examples clarifying constraints
Validation          -> Commands or criteria to verify output
```

Every skill declares the same frontmatter keys:

| Key | Value |
|-----|-------|
| `name` | Directory name |
| `description` | What the skill does, one sentence |
| `when_to_use` | Trigger phrases, Korean request examples, and "Not for" hand-offs to sibling skills |
| `argument-hint` | Autocomplete hint, `<required>` or `[optional]` |
| `license` | `Apache-2.0` |
| `compatibility` | Required CLIs and environment |
| `metadata` | `version`, `category` (generator, validator, action, style), `related` skills |
| `allowed-tools` | Tools pre-approved while the skill runs, Bash scoped by command pattern |
| `user-invocable` | `true` |
| `disable-model-invocation` | `false` |

`model`, `effort`, `context`, `paths`, and `hooks` are left unset so skills run in the session's own context and settings.

Keep the body under 100 lines, frontmatter excluded. Omit general knowledge the model already has and keep only your conventions and constraints.

## License

Licensed under the [Apache License 2.0](../../LICENSE).
