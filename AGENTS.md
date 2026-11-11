# AGENTS.md

Guidance for coding agents working in this repository. Only non-derivable conventions and traps live here.

## Never publish personal data

This repository is public, including commit messages. Work-specific git includes, signing keys, and site values live in untracked local files: configs/git/config-work, configs/git/config-work-identity, .key files in configs/git/, and ~/.zshrc.local. .gitignore keeps them out. Never commit company names, work gitdir paths, internal hosts, IP ranges, account IDs, or ticket keys. Never run git add -A or git add . here, stage explicit paths and check git status --ignored before committing.

## Git

Commit directly to main with a DCO sign-off (git commit -s). GPG signing is on globally.

Run pre-commit install once per clone. It installs both the pre-commit and commit-msg hooks, which enforce the commit format and sign-off below. Fix hook failures instead of bypassing them with --no-verify.

Format: TOOL TYPE(SCOPE): DETAIL, for example [nvim] feat(pack): add nvim-treesitter-textobjects via vim.pack. TOOL is the directory name under configs/, or [repo] for changes that span tools. Types: feat, fix, refactor, docs, test, chore.

## Dotfiles rules

- **Never edit symlinked targets** (~/.config/nvim, ~/.zshrc, ...). Edit the source here instead.
- **Repository path**: repoDir in flake.nix expects this repository at $HOME/github/younsl/nix, and every config link resolves through it. Scripts resolve their own location.
- **Adding or moving a config needs a matching home.file entry in nix/home/links.nix**, then run darwin-rebuild switch. Links use mkOutOfStoreSymlink so tools that rewrite their own files (vim.pack lockfile, Claude Code settings) keep working. Never switch them to store paths.
- **darwin-rebuild runs as sudo darwin-rebuild switch --flake .#macbook --impure**. The flake reads SUDO_USER so the login name stays out of this public repository. Never hard-code the username or hostname.
- **Flakes ignore untracked files**: git add -N a new .nix file before evaluating it. Format .nix files with nix fmt (nixfmt).
- **Scripts carry no comments** and every script starts with set -euo pipefail.
- scripts/git/commit-history-cleaner.sh and the chc alias are **destructive**: they wipe all history and force push. Never run them in this repository.
- bootstrap.sh is #!/bin/zsh: prompts must use read "VAR?prompt". zsh's read -p reads from a coprocess and silently yields an empty value.
- configs/launchd/kavd-watchdog is a local Rust tool, not released. It follows edition 2024, rust-version 1.99.1, cargo fmt --check, and cargo clippy -- -D warnings. nix/pkgs/kavd-watchdog.nix builds it with the toolchain named by rust-version, and nix-darwin runs it from the store as a launchd daemon.

## Shell entry points

Single-letter aliases are load-bearing in daily use. Never rename or shadow them, and never define a new alias that collides. Defined in configs/zsh/.zshrc unless noted.

| Command | Expands to | Source |
|---|---|---|
| c | claude (often c --worktree) | alias |
| k | kubectl | oh-my-zsh kubectl plugin |
| s CONTEXT | switch CONTEXT (kubeswitch) | alias + switcher init zsh |
| j DIR | jump to a frecent directory | oh-my-zsh autojump plugin |
| tgp / tga / tgd / tgo / tgf / tgfu | terragrunt plan/apply/destroy/output/hcl fmt/force-unlock | alias |
| git sweep | prune remote-tracking refs, then delete local [gone] branches (removes their worktrees first) | configs/git/config |
| git br | branches by last commit date, in a column table | configs/git/config |
| chc | commit-history-cleaner, **destructive** | alias + configs/zsh/functions/ |

k and j come from oh-my-zsh plugins, so the plugins=() list in .zshrc is load-bearing beyond completion. Dropping kubectl or autojump removes the command itself.

## Tool notes

- **zsh**: fast-syntax-highlighting must stay **last** in plugins. It wraps ZLE widgets and only sees widgets registered before it. Never add zsh-syntax-highlighting alongside it: the buffer is re-parsed twice per keystroke and the later one overwrites the earlier one's region_highlight.
- **mise**: owns every version-sensitive CLI. Add runtimes with mise use -g TOOL@VERSION so the pin lands in configs/package-managers/mise/config.toml.
- **istioctl**: pinned in mise, never nixpkgs or brew. It is version-coupled to the control plane, and either one's upgrades would bump it past the mesh.
- **nvim**: plugins are managed by built-in vim.pack (configs/nvim/lua/config/pack.lua) and pinned in nvim-pack-lock.json. Auto-update runs daily on VimEnter and rewrites the lockfile, so commit it after it changes. Prefer a native Neovim feature over a plugin.
- **git**: per-org profiles selected by includeIf gitdir:. Work profiles go in the untracked config-work.
- **Packages**: CLI tools go in nix/home/packages.nix, kept sorted. Homebrew holds only casks and formulae that nixpkgs lacks or cannot build on darwin, in nix/darwin/homebrew.nix. Its cleanup is uninstall, so a hand-run brew install disappears on the next switch.
- **kubectl plugins**: nixpkgs packages in nix/home/packages.nix, not krew. kubectl finds kubectl-NAME binaries on PATH, and nix/home/commands.nix adds a kubectl-stern link so kubectl stern keeps working.
- **scripts/git/clone-all.sh** ships as the clone-all command through writeShellApplication in nix/home/commands.nix, which pins its runtime tools and shellchecks it at build time.
