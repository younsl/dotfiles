# dotfiles

Personal macOS dotfiles, linked into the home directory with plain symlinks by [install.sh](install.sh).

Dotfile managers such as [chezmoi](https://www.chezmoi.io/), [GNU Stow](https://www.gnu.org/software/stow/), and [Nix](https://nixos.org/) are intentionally not used.

## Layout

| Path | Contents |
| --- | --- |
| configs | One directory per tool, package managers under configs/package-managers/, LaunchDaemons under configs/launchd/ (installed by their own install.sh) |
| scripts | Bootstrap, repo cloning, krew and Brewfile backup |
| [install.sh](install.sh) | Which config links to which home target |

## Fresh machine

```bash
git clone https://github.com/younsl/dotfiles ~/github/younsl/dotfiles
~/github/younsl/dotfiles/scripts/bootstrap/bootstrap-dotfiles.sh
~/github/younsl/dotfiles/scripts/bootstrap/bootstrap-omz.sh
```

bootstrap-dotfiles.sh runs install.sh, installs pre-commit hooks, and turns on Homebrew autoupdate. bootstrap-omz.sh installs Oh My Zsh and its plugins.

## Linking

```bash
./install.sh --dry-run
./install.sh
```

install.sh is idempotent. A link already in place is left alone, a symlink pointing elsewhere is replaced, and a real file in the way is moved to ~/.dotfiles-backup/TIMESTAMP/ instead of being deleted. ~/.claude/skills gets one link per skill directory, so files other tools add there stay put, and dangling links in it are pruned.

To add a config, put it under configs/TOOL/, add a source:target pair to LINKS in install.sh, and run install.sh again.

## Local-only files

This repository is public. These files are loaded at runtime but gitignored, and never committed:

| File | Purpose |
| --- | --- |
| configs/git/config-work, configs/git/config-work-identity | Work git settings, including work includeIf gitdir: profiles. Included by configs/git/config |
| .key files in configs/git/ | Signing key settings |
| configs/claude/scripts/statusbar-rs | Compiled status line binary, built from configs/claude/scripts/statusbar |
| ~/.zshrc.local | Site values such as Jira and registry hosts for Claude Code skills, sourced last by .zshrc |

## Package files

The Brewfile and krewfile are snapshots. Refresh them with scripts/package-managers/manage-krew-brew.sh and commit the change.
