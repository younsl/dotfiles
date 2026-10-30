# AGENTS.md

Guidance for coding agents working in this repository. Only non-derivable conventions and traps live here.

## Never publish personal data

This repository is public, including commit messages. Work-specific git includes, signing keys, and site values live in untracked local files: git/config-work, git/config-work-identity, .key files in git/, and ~/.zshrc.local. .gitignore keeps them out. Never commit company names, work gitdir paths, internal hosts, IP ranges, account IDs, or ticket keys. Never run git add -A or git add . here, stage explicit paths and check git status --ignored before committing.

## Git

Commit directly to main with a DCO sign-off (git commit -s). GPG signing is on globally.

Format: TOOL TYPE(SCOPE): DETAIL, for example [nvim] feat(pack): add nvim-treesitter-textobjects via vim.pack. TOOL is the top-level directory name, or [repo] for changes that span tools. Types: feat, fix, refactor, docs, test, chore.

## Dotfiles rules

- **Never edit symlinked targets** (~/.config/nvim, ~/.zshrc, ...). Edit the source here instead.
- **Hard-coded path**: the bootstrap and package scripts expect this repository at $HOME/github/younsl/dotfiles. install.sh resolves its own location.
- **Adding or moving a config needs a matching LINKS entry in install.sh**, then run install.sh again.
- **Scripts carry no comments** and every script starts with set -euo pipefail.
- scripts/git/commit-history-cleaner.sh and the chc alias are **destructive**: they wipe all history and force push. Never run them in this repository.
- bootstrap-dotfiles.sh is #!/bin/zsh: prompts must use read "VAR?prompt". zsh's read -p reads from a coprocess and silently yields an empty value.
- claude/scripts/statusbar and launchd/kavd-watchdog are local Rust tools, not released. They follow edition 2024, rust-version 1.99.1, cargo fmt --check, and cargo clippy -- -D warnings.

## Shell entry points

Single-letter aliases are load-bearing in daily use. Never rename or shadow them, and never define a new alias that collides. Defined in zsh/.zshrc unless noted.

| Command | Expands to | Source |
|---|---|---|
| c | claude (often c --worktree) | alias |
| k | kubectl | oh-my-zsh kubectl plugin |
| s CONTEXT | switch CONTEXT (kubeswitch) | alias + switcher init zsh |
| j DIR | jump to a frecent directory | oh-my-zsh autojump plugin |
| tgp / tga / tgd / tgo / tgf / tgfu | terragrunt plan/apply/destroy/output/hcl fmt/force-unlock | alias |
| git sweep | prune remote-tracking refs, then delete local [gone] branches (removes their worktrees first) | git/config |
| git br | branches by last commit date, in a column table | git/config |
| chc | commit-history-cleaner, **destructive** | alias + zsh/functions/ |

k and j come from oh-my-zsh plugins, so the plugins=() list in .zshrc is load-bearing beyond completion. Dropping kubectl or autojump removes the command itself.

## Tool notes

- **zsh**: fast-syntax-highlighting must stay **last** in plugins. It wraps ZLE widgets and only sees widgets registered before it. Never add zsh-syntax-highlighting alongside it: the buffer is re-parsed twice per keystroke and the later one overwrites the earlier one's region_highlight.
- **mise**: owns every version-sensitive CLI. Add runtimes with mise use -g TOOL@VERSION so the pin lands in package-managers/mise/config.toml.
- **istioctl**: pinned in mise, never brew. It is version-coupled to the control plane and brew's daily --upgrade would bump it past the mesh.
- **nvim**: plugins are managed by built-in vim.pack (nvim/lua/config/pack.lua) and pinned in nvim-pack-lock.json. Auto-update runs daily on VimEnter and rewrites the lockfile, so commit it after it changes. Prefer a native Neovim feature over a plugin.
- **git**: per-org profiles selected by includeIf gitdir:. Work profiles go in the untracked config-work.
- **Brewfile and krewfile**: snapshots refreshed by scripts/package-managers/manage-krew-brew.sh, never edited by hand.
