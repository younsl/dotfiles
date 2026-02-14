# Dotfiles List

## Summary

This page describes all supported dotfiles of dotfiles repository.

## System Requirements

These dotfiles are optimized for [macOS Sequoia](https://www.apple.com/kr/macos/macos-sequoia/) 15.x.

## Supported dotfiles

| No. | Component Name | Category | Bootstrapped | Symlink path |
|-----|----------------|----------|--------------|--------------|
| 1 | brew | Package Manager | Supported | Not applicable |
| 2 | krew | Package Manager | Supported | Not applicable |
| 3 | pip | Package Manager | Supported | $HOME/.config/pip |
| 4 | fortune | Terminal Utility | Supported | $HOME/.config/fortune |
| 5 | git | Git Utility | Supported | $HOME/.config/git |
| 6 | ghostty | Terminal | Supported | $HOME/.config/ghostty |
| 7 | k9s | Kubernetes | Supported | $HOME/.config/k9s |
| 8 | fastfetch | Terminal Utility | Supported | $HOME/.config/fastfetch |
| 9 | zsh | Terminal | Supported | $HOME/.zshrc |
| 10 | nvim | IDE | Supported | $HOME/.config/nvim |
| 11 | gnupg | Git Utility | Supported | $HOME/.gnupg [^gpg-note] |
| 12 | claude | AI Assistant | Supported | $HOME/.claude/settings.json |

[^gpg-note]: Manages only common, non-sensitive GPG configurations for `gnupg`, excluding sensitive files.