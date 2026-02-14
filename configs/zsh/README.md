# zsh

Zsh configuration for macOS with [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh). Theme: `clean`.

## Structure

```
zsh/
├── .zshrc        # Main configuration
├── .zshrc.local  # Machine-specific config (gitignored)
└── functions/    # Custom functions (autoloaded via fpath)
    └── commit-history-cleaner
```

## Aliases

| Alias | Command |
|-------|---------|
| `vi`, `vim` | nvim |
| `python`, `pip` | python3, pip3 |
| `docker` | podman |
| `c` | claude |
| `chc` | commit-history-cleaner |
| `tgp`, `tga`, `tgo`, `tgf` | terragrunt plan/apply/output/hclfmt |

## Functions

Functions are lazy-loaded on first invocation. Add new functions by placing a file (no extension, function body only) in `functions/`.

| Function | Description |
|----------|-------------|
| `commit-history-cleaner` | Clean all git commit history by creating an orphan branch |
