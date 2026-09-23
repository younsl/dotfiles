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
| 4 | git | Git Utility | Supported | $HOME/.config/git |
| 5 | ghostty | Terminal | Supported | $HOME/.config/ghostty |
| 6 | k9s | Kubernetes | Supported | $HOME/.config/k9s |
| 7 | mise | Package Manager | Supported | $HOME/.config/mise |
| 8 | zsh | Terminal | Supported | $HOME/.zshrc |
| 9 | nvim | IDE | Supported | $HOME/.config/nvim |
| 10 | gnupg | Git Utility | Supported | $HOME/.gnupg [^gpg-note] |
| 11 | claude | AI Assistant | Supported | $HOME/.claude/settings.json |

[^gpg-note]: Manages only common, non-sensitive GPG configurations for `gnupg`, excluding sensitive files.