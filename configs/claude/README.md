# Claude Code

Configuration files for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

```
claude/
├── CLAUDE.md            # Global instructions (loaded into system prompt)
├── settings.json        # User settings, plugins, and hooks
├── hooks/
│   └── post-edit-rs.sh  # Auto-runs rustfmt on .rs file edits
├── scripts/
│   ├── context-monitor/ # Status line context monitor (Rust source)
│   └── context-monitor-rs  # Compiled binary (arm64)
└── skills/              # Custom slash command skills
```

## Scripts

[`context-monitor-rs`](./scripts/context-monitor-rs) is a [Rust](https://github.com/rust-lang/rust)-based status line binary for Claude Code. Source is in [`scripts/context-monitor/`](./scripts/context-monitor/).
