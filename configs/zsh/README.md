# zsh

Zsh configuration for macOS with Oh My Zsh.

## Why Oh My Zsh

[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) is a Zsh configuration framework that provides themes, plugins, and sensible defaults out of the box. It simplifies shell customization without requiring deep Zsh knowledge.

## Structure

```
zsh/
├── .zshrc        # Main zsh configuration
└── .zshrc.local  # Local config (gitignored, for sensitive data)
```

## Overview

| Section | Description |
|---------|-------------|
| PATH | rustup, krew, python user bin |
| Oh My Zsh | Theme: `clean`, 11 plugins enabled |
| Prompt | kube-ps1 integration, custom format |
| Aliases | python, neovim, podman, claude, terragrunt |

## Plugins

Oh My Zsh plugins enabled in `.zshrc`:

- git
- zsh-syntax-highlighting
- zsh-autosuggestions
- fast-syntax-highlighting
- zsh-autocomplete
- tmux
- autojump
- fzf
- kubectl
- aws
- kube-ps1

## Aliases

| Alias | Command |
|-------|---------|
| `vi`, `vim` | nvim |
| `python`, `pip` | python3, pip3 |
| `docker` | podman |
| `c` | claude |
| `tga`, `tgp`, `tgo`, `tgf` | terragrunt apply/plan/output/hclfmt |

## Local Config

Create `~/.zshrc.local` for machine-specific or sensitive configurations. This file is automatically sourced if it exists and is excluded from git.

## Reference

- [Oh My Zsh plugins setup guide](https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df)
