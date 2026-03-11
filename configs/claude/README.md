# Claude Code

Configuration files for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

```
claude/
├── CLAUDE.md       # Global instructions (loaded into system prompt)
├── settings.json   # User settings, plugins, and hooks
├── hooks/
│   └── *.sh        # Hook scripts (e.g., rustfmt on .rs edits)
├── scripts/
│   └── context-monitor.py  # Status line context monitor
└── skills/         # Custom slash command skills
```

## Context Monitor

`context-monitor.py` is a status line script that displays real-time session information at the bottom of the Claude Code terminal.

### Display

```
[Claude Opus 4.6/ High] 📁 dotfiles 🧠 🟢██▁▁▁▁▁▁ 23% | 💰 $0.034 ⏱ 5m 📝 +12
```

| Component | Description |
|-----------|-------------|
| `[Model/ Effort]` | Current model and effort level from `settings.json` |
| `📁 dir` | Working directory (relative to project root) |
| `🧠 bar N%` | Context window usage with 8-segment progress bar |
| `💰 cost` | Session cost (green < 5¢, yellow < 10¢, red >= 10¢) |
| `⏱ time` | Session duration |
| `📝 ±lines` | Net lines changed |

Context usage indicators:

| Icon | Range | Meaning |
|------|-------|---------|
| 🟢 | 0–49% | Normal |
| 🟡 | 50–74% | Moderate |
| 🟠 | 75–89% | High |
| 🔴 | 90–94% | Very high |
| 🚨 | 95–100% | Critical |

### Setup

Add the following to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/scripts/context-monitor.py"
  }
}
```

The bootstrap script automatically creates a symlink from `~/.claude/scripts` to this directory.
