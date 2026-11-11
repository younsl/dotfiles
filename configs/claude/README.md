# Claude Code

Configuration files for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

```
claude/
├── AGENTS.md            # Global instructions (loaded into system prompt)
├── settings.json        # User settings, plugins, and hooks
├── hooks/
│   └── post-edit-rs.sh  # Auto-runs rustfmt on .rs file edits
```

Skills moved to the [houston](https://github.com/younsl/skills) plugin in younsl/skills.

## AI Disclosure

The entire codebase of this project was developed with the assistance of [Claude Opus 5.5](https://www.anthropic.com/claude/opus) (High effort).
