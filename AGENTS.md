# AGENTS.md

Personal macOS dotfiles. `configs/<tool>/` holds every config; bootstrap symlinks them into place.

## Commit Message Convention

Format: `[<DOTFILE>] <type>(<scope>): <detail message>`

- `<DOTFILE>` is the tool or config being changed. Use `[repo]` when it belongs to no single tool.
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, etc.

Examples:
- `[nvim] feat(plugin): add lazy.nvim telescope extension`
- `[zsh] fix(alias): correct kubectl alias conflict`
- `[repo] chore(docs): update AGENTS.md`

## Critical Rules

- **Never edit symlinked targets** (`~/.config/nvim`, `~/.zshrc`, …). Edit the source in `configs/` instead.
- **Hard-coded path**: bootstrap expects the repo at `$HOME/github/younsl/dotfiles` (`DOTFILES_DIR`).
- **Scripts carry no comments.** Keep them self-explanatory through naming; do not reintroduce comment blocks.
- **Every script starts with `set -euo pipefail`.**
- `scripts/git/commit-history-cleaner.sh` is **destructive** — wipes all history and force pushes.

## Shell Entry Points

Single-letter aliases are load-bearing in daily use; never rename or shadow them, and never define a
new alias that collides. Defined in `configs/zsh/.zshrc` unless noted.

| Command | Expands to | Source |
|---|---|---|
| `c` | `claude` (often `c --worktree`) | alias |
| `k` | `kubectl` | oh-my-zsh `kubectl` plugin |
| `s <context>` | `switch <context>` — kubeswitch | alias + `switcher init zsh` |
| `j <dir>` | jump to a frecent directory | oh-my-zsh `autojump` plugin |
| `tgp` / `tga` / `tgd` / `tgo` / `tgf` / `tgfu` | `terragrunt plan/apply/destroy/output/hclfmt/force-unlock` | alias |
| `git sweep` | prune remote-tracking refs, then delete local `[gone]` branches (removes their worktrees first) | `configs/git/config` |
| `git br` | branches by last commit date, in a column table | `configs/git/config` |
| `chc` | `commit-history-cleaner` — **destructive**, wipes all history and force pushes | alias + `configs/zsh/functions/` |

`k` and `j` come from oh-my-zsh plugins, so the `plugins=()` list in `.zshrc` is load-bearing beyond
completion — dropping `kubectl` or `autojump` removes the command itself.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/bootstrap/bootstrap-dotfiles.sh` | Symlinks, pre-commit install, brew autoupdate (86400s, `--upgrade --cleanup --immediate`) |
| `scripts/bootstrap/bootstrap-omz.sh` | Oh My Zsh + `zsh-autosuggestions`, `fast-syntax-highlighting` |
| `scripts/package-managers/manage-krew-brew.sh` | Interactive krew backup/restore, manual Brewfile dump |
| `scripts/git/clone-all.sh` | Bulk clone all GitHub repos for `younsl` |

`bootstrap-dotfiles.sh` is `#!/bin/zsh`: prompts must use `read "VAR?prompt"` — zsh's `read -p` reads from a coprocess and silently yields an empty value.

### Symlink semantics

`COMPONENTS` in `bootstrap-dotfiles.sh` is the source of truth for mappings. Behavior of `link_component()`:

- correct link already present → no-op (rerunning is safe)
- link pointing elsewhere → replaced
- real file or directory → **moved** to `~/.dotfiles-backup/<timestamp>/`, never deleted

Special case: `zshrc` links from `configs/zsh/.zshrc`.

## Pre-commit Hooks

`.pre-commit-config.yaml`, installed by bootstrap (`pre-commit install` to redo):

- **gitleaks** — secret scan. This repo is public; never commit real credentials, internal hostnames, or account IDs.
- **backup-brewfile** — `language: system`, `always_run: true`. Dumps Brewfile once per day (date tracked in `.brewfile-last-backup`), appends a package-count summary, auto-stages it.

## Tool Notes

Only the non-obvious constraints; the rest is readable from `configs/`.

- **zsh**: `fast-syntax-highlighting` must stay **last** in `plugins` — it wraps ZLE widgets and only sees widgets registered before it. Never add `zsh-syntax-highlighting` alongside it: same feature, two implementations, so the buffer is re-parsed twice per keystroke and the later one overwrites the earlier one's `region_highlight`.
- **mise**: replaced nvm, which sourced two shell scripts and forked `brew --prefix` twice per shell start. Runtimes are pinned in `configs/mise/config.toml`; add new ones with `mise use -g <tool>@<version>` so the change lands in tracked config. It owns every version-sensitive CLI, so nothing needs a hand-rolled installer or its own PATH entry.
- **istioctl**: pinned in `configs/mise/config.toml`, never brew — istioctl is version-coupled to the control plane and brew's daily `--upgrade` would silently bump it past the mesh. Bump it with `mise use -g istioctl@<version>` so the pin lands in tracked config.
- **git**: per-org profiles selected by `includeIf gitdir:`; GPG signing is on globally.
- **zsh local overrides**: `~/.zshrc.local` is gitignored, sourced last.
