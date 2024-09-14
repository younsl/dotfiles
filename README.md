# dotfiles

[![Badge - Last commit](https://img.shields.io/github/last-commit/younsl/dotfiles.svg)](https://github.com/younsl/dotfiles/commits/main)
![Badge - Github stars](https://img.shields.io/github/stars/younsl/dotfiles.svg?label=stars)
![Badge - Github forks](https://img.shields.io/github/forks/younsl/dotfiles.svg?label=forks)
[![Badge - License](https://img.shields.io/badge/license-MIT-ff69b4.svg)](https://github.com/younsl/dotfiles/blob/main/LICENSE)

## Overview

My standard dotfiles for Mac.

> [!NOTE]
> I use this dotfile on both my work and personal macbook.

## Supported dotfiles

| No. | Name      | Category        | Bootstrapped |
|-----|-----------|-----------------|--------------|
| 1   | brew      | Package Manager | ✅ Yes |
| 2   | krew      | Package Manager | ✅ Yes |
| 3   | pip       | Package Manager | ✅ Yes |
| 4   | fortune   | Terminal        | ✅ Yes |
| 5   | git       | Terminal        | ✅ Yes |
| 6   | iterm2    | Terminal        | ✅ Yes |
| 7   | k9s       | Terminal        | ✅ Yes |
| 8   | neofetch  | Terminal        | ✅ Yes |
| 9   | zsh       | Terminal        | ✅ Yes |
| 10  | vscode    | IDE             | ❌ No |

### fortune strfile automation using pre-commit hook

When you commit a `*.fortune` file, the local `*.fortune.dat` file is automatically updated automatically.

```bash
$ git commit -m "style: Linting indent"
gitstrfile-fortune..........................................................Passed
[main a30b41e] style: Linting indent
 1 file changed, 6 insertions(+), 6 deletions(-)
```

See the precommit-hook configuration file [.pre-commit-config.yaml](https://github.com/younsl/dotfiles/blob/main/.pre-commit-config.yaml) for details.

## Reference

[본격 macOS에 개발 환경 구축하기](https://subicura.com/2017/11/22/mac-os-development-environment-setup.html)
