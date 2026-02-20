# Claude Code

Configuration files for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

```
claude/
├── CLAUDE.md       # Global instructions (loaded into system prompt)
├── settings.json   # User settings, plugins, and hooks
├── hooks/
│   └── *.sh        # Hook scripts (e.g., rustfmt on .rs edits)
└── skills/         # Custom slash command skills
```
