# dotfiles

[![Badge - Last commit](https://img.shields.io/github/last-commit/younsl/dotfiles.svg)](https://github.com/younsl/dotfiles/commits/main)
![Badge - Github stars](https://img.shields.io/github/stars/younsl/dotfiles.svg?label=stars)
![Badge - Github forks](https://img.shields.io/github/forks/younsl/dotfiles.svg?label=forks)
[![Badge - License](https://img.shields.io/badge/license-MIT-ff69b4.svg)](https://github.com/younsl/dotfiles/blob/main/LICENSE)

## Overview

My standard dotfiles for Mac.

> **Note**:  
> I use this dotfile on both my work and personal MacBook.

## Supported dotfiles

| No. | Name      | Category          | Bootstrap Script Support |
|-----|-----------|-------------------|--------------------------|
| 1   | brew      | Package Manager   | ✅                       |
| 2   | krew      | Package Manager   | ✅                       |
| 3   | fortune   | Terminal          | ✅                       |
| 4   | git       | Terminal          | ✅                       |
| 5   | iterm2    | Terminal          | ✅                       |
| 6   | k9s       | Terminal          | ✅                       |
| 7   | neofetch  | Terminal          | ✅                       |
| 8   | zsh       | Terminal          | ✅                       |
| 9   | vscode    | IDE               | ❌                       |

### fortune strfile automation using pre-commit hook

When you commit a `*.fortune` file, the local `*.fortune.dat` file is automatically updated automatically.

See the precommit-hook configuration file [.pre-commit-config.yaml](https://github.com/younsl/dotfiles/blob/main/.pre-commit-config.yaml) for details.

## Reference

[본격 macOS에 개발 환경 구축하기](https://subicura.com/2017/11/22/mac-os-development-environment-setup.html)
