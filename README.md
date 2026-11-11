# nix

Personal macOS configuration as a [Nix](https://github.com/NixOS/nix) flake. [nix-darwin](https://github.com/nix-darwin/nix-darwin) owns the system, [home-manager](https://github.com/nix-community/home-manager) owns the user environment, and configs/ holds the files each tool reads.

## Layout

```
.
├── flake.nix          # inputs and the macbook darwin configuration
├── flake.lock
├── nix/
│   ├── darwin/        # system defaults, Homebrew taps and casks, kavd-watchdog daemon
│   ├── home/          # CLI packages, wrapped scripts, config links, oh-my-zsh
│   ├── pkgs/          # local package builds
│   └── overlays.nix   # fixes applied on top of nixpkgs
├── configs/           # config files linked into $HOME
└── scripts/           # bootstrap and standalone scripts
```

## Install

Clone into the fixed path, then run the bootstrap. It installs [Determinate Nix](https://github.com/DeterminateSystems/nix-installer) and [Homebrew](https://github.com/Homebrew/brew) when missing, moves the stock /etc shell files aside for nix-darwin, and runs the first switch.

```bash
git clone https://github.com/younsl/nix ~/github/younsl/nix
~/github/younsl/nix/scripts/bootstrap/bootstrap.sh
```

## Usage

Nothing applies on its own. Edit a file, then switch:

```bash
sudo darwin-rebuild switch --flake ~/github/younsl/nix#macbook --impure
```

The flake reads SUDO_USER, which needs --impure, so the login name never lands in this public repository.

Update every pinned input, then switch and commit flake.lock:

```bash
nix flake update --flake ~/github/younsl/nix
```

Roll back to the previous generation:

```bash
sudo darwin-rebuild --rollback
```

Try a package without installing it:

```bash
nix shell nixpkgs#stern
```

## Packages

- **[nixpkgs](https://github.com/NixOS/nixpkgs)**: CLI tools and kubectl plugins, declared in nix/home/packages.nix.
- **writeShellApplication**: scripts shipped as commands, such as clone-all, declared in nix/home/commands.nix.
- **Homebrew**: casks and formulae that nixpkgs lacks or cannot build on darwin, declared in nix/darwin/homebrew.nix. Cleanup is set to uninstall, so a hand-run brew install disappears on the next switch.
- **[mise](https://github.com/jdx/mise)**: version-coupled CLIs such as istioctl, pinned in configs/package-managers/mise/config.toml.

## Config links

home-manager links each path under configs/ into $HOME outside the Nix store. Edits apply immediately without a switch, and tools that rewrite their own files, such as the vim.pack lockfile and Claude Code settings, keep working. A new or moved config needs an entry in nix/home/links.nix.

## Private files

Work git settings, signing keys, and ~/.zshrc.local stay local and gitignored.
