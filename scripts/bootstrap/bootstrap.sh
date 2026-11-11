#!/bin/zsh

set -euo pipefail

REPO_DIR="${0:A:h:h:h}"
ADDONS_DIR="$HOME/github/younsl/addons"
FLAKE="$REPO_DIR#macbook"
NIX_BIN="/nix/var/nix/profiles/default/bin"
ETC_SHELL_FILES=(/etc/zshrc /etc/zshenv /etc/zprofile /etc/bashrc)

REPLY=""

print_plan() {
    echo "Apply the nix-darwin and home-manager configuration:"
    echo "  flake: $FLAKE"
    echo "  steps: install Nix and Homebrew if missing, then darwin-rebuild switch"
}

prompt_user() {
    read "REPLY?Do you want to proceed with this action? (yY/n): " || REPLY=""
    echo
}

install_nix() {
    if [[ -x "$NIX_BIN/nix" ]]; then
        echo "$("$NIX_BIN/nix" --version) is already installed."
    else
        echo "Installing Nix with the Determinate Systems installer ..."
        curl -fsSL https://install.determinate.systems/nix | sh -s -- install
    fi
    path=("$NIX_BIN" $path)
}

install_homebrew() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        echo "Homebrew is already installed."
    else
        echo "Installing Homebrew for casks ..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

release_etc_shell_files() {
    local file
    for file in "${ETC_SHELL_FILES[@]}"; do
        if [[ -f $file && ! -L $file ]]; then
            echo "Moving $file to $file.before-nix-darwin ..."
            sudo mv "$file" "$file.before-nix-darwin"
        fi
    done
}

darwin_switch() {
    if command -v darwin-rebuild &>/dev/null; then
        sudo darwin-rebuild switch --flake "$FLAKE" --impure
    else
        sudo "$NIX_BIN/nix" run --inputs-from "$REPO_DIR" nix-darwin#darwin-rebuild -- \
            switch --flake "$FLAKE" --impure
    fi
}

install_precommit_hooks() {
    local precommit="/etc/profiles/per-user/$USER/bin/pre-commit"
    local repo
    for repo in "$REPO_DIR" "$ADDONS_DIR"; do
        if [[ -e "$repo/.git" ]]; then
            (cd "$repo" && "$precommit" install)
        fi
    done
}

main() {
    print_plan
    prompt_user

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return
    fi

    install_nix
    install_homebrew
    release_etc_shell_files
    darwin_switch
    install_precommit_hooks
}

main
