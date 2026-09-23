# Claude Code

Configuration files for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Structure

```
claude/
├── AGENTS.md            # Global instructions (loaded into system prompt)
├── settings.json        # User settings, plugins, and hooks
├── hooks/
│   └── post-edit-rs.sh  # Auto-runs rustfmt on .rs file edits
└── scripts/
    ├── statusbar/       # Status line binary (Rust source)
    └── statusbar-rs     # Compiled binary (arm64)
```

Skills live in [`../skills`](../skills) and are shared with every agent that reads the Agent Skills format. The bootstrap script links each one into `~/.claude/skills/`.

## Scripts

`statusbar-rs` is a [Rust](https://github.com/rust-lang/rust)-based status line binary for Claude Code. Source is in [`scripts/statusbar/`](./scripts/statusbar/).

Segments, separated by `|` and each omitted when its data is absent:

```
Opus 5 High dotfiles on main ctx:32% | 5h 22% | week 44% | cpu 38% mem 51% | +40L
```

| Segment | Source field |
|---|---|
| `ctx:<pct>` | `context_window.used_percentage` (hidden at 0%) |
| `5h <pct>` | `rate_limits.five_hour.used_percentage` |
| `week <pct>` | `rate_limits.seven_day.used_percentage` |
| `cpu <pct>` | `sysctl vm.loadavg` 1-minute load / `hw.ncpu` |
| `mem <pct>` | `vm_stat` active + wired + compressor pages / `hw.memsize` |
| `+<net>L` | `cost.total_lines_added` / `total_lines_removed` |

Rate limit percentages come straight from the status line JSON on stdin, so they match `/usage`; they are only present for Pro/Max plans. The last seen values are cached in `~/.claude/cache/statusbar-limits.json` because early renders in a fresh session carry no `rate_limits`, and cached windows are dropped once their `resets_at` passes.

Session cost and elapsed time are deliberately omitted — the rate limit percentages already carry the usage signal.
