# Claude Code

Configuration files for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

```
claude/
├── CLAUDE.md       # Global instructions (loaded into system prompt)
├── settings.json   # User settings, plugins, and hooks
├── hooks/
│   ├── sounds/     # WC3 Peasant voice hooks for fun coding sessions
│   └── *.sh        # Hook scripts (e.g., rustfmt on .rs edits)
└── skills/         # Custom slash command skills
```

## Hooks Setup

```bash
curl -fsSL https://raw.githubusercontent.com/younsl/dotfiles/main/configs/claude/hooks/setup.sh | bash
```

See [hooks/README.md](hooks/README.md) for details.
