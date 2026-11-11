# nix

Personal macOS configuration as a Nix flake. nix-darwin owns system settings, launchd daemons, and Homebrew casks. home-manager owns CLI packages and links each file under configs/ into $HOME outside the Nix store, so tools that rewrite their own config keep working.

```bash
git clone https://github.com/younsl/nix ~/github/younsl/nix
~/github/younsl/nix/scripts/bootstrap/bootstrap.sh
```

Apply changes after the first run:

```bash
sudo darwin-rebuild switch --flake ~/github/younsl/nix#macbook --impure
```

The flake reads SUDO_USER, which needs --impure, so the login name never lands in this public repository.

| Path | Content |
| --- | --- |
| flake.nix | Inputs and the macbook darwin configuration |
| nix/darwin | System defaults, Homebrew taps and casks, kavd-watchdog daemon |
| nix/home | CLI packages, config links, oh-my-zsh and its plugins |
| nix/pkgs | Local package builds |
| configs | Config files linked into $HOME |

Version-sensitive CLIs such as istioctl stay in mise. Casks and the few formulae nixpkgs cannot build on macOS stay in Homebrew, declared in nix/darwin/homebrew.nix.

Work git settings, signing keys, and ~/.zshrc.local stay local and gitignored.
