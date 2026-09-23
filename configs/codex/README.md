# Codex

Configuration files for OpenAI Codex.

## Structure

```
codex/
└── config.toml          # Git-tracked base config, without MCP credentials
```

Skills live in [`../skills`](../skills) and are shared with every agent that reads the Agent Skills format. The bootstrap script links each one into `~/.agents/skills/`, the user-level location Codex scans.

## Setup

The bootstrap script applies `config.toml`, links the shared skills, and links the global instructions in [`../claude/AGENTS.md`](../claude/AGENTS.md) to `~/.codex/AGENTS.md`:

```bash
./scripts/bootstrap/bootstrap-dotfiles.sh
```

MCP server credentials stay in local `~/.codex/config.toml` and are not tracked in this public dotfiles repository.

Project trust entries also stay local because they can contain machine-specific or company repository paths.
