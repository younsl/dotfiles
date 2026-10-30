#!/bin/zsh

set -euo pipefail

DOTFILES_DIR="$HOME/github/younsl/dotfiles"
ADDONS_DIR="$HOME/github/younsl/addons"

REPLY=""

print_plan() {
    echo "Symlink dotfiles into $HOME:"
    echo "  source: $DOTFILES_DIR"
    echo "  installer: $DOTFILES_DIR/install.sh"
}

prompt_user() {
    read "REPLY?Do you want to proceed with this action? (yY/n): " || REPLY=""
    echo
}

install_precommit() {
  if ! command -v pre-commit &>/dev/null; then
    echo "pre-commit not found. Installing via Homebrew ..."
    brew install pre-commit
  else
    pre_commit_version=$(pre-commit --version)
    echo "pre-commit $pre_commit_version is already installed."
  fi

  printf "\n"
}

configure_brew_autoupdate() {
  if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed. Skipping brew autoupdate configuration."
    printf "\n"
    return
  fi

  local autoupdate_interval=86400

  echo "Configuring brew autoupdate ..."

  if ! brew tap | grep -q "homebrew/autoupdate"; then
    echo "Installing homebrew/autoupdate tap ..."
    brew tap homebrew/autoupdate
  else
    echo "homebrew/autoupdate tap is already installed."
  fi

  if brew autoupdate status 2>/dev/null | grep -q "running"; then
    echo "Brew autoupdate is already configured and running."
  else
    echo "Starting brew autoupdate with $autoupdate_interval seconds interval ..."
    brew autoupdate start $autoupdate_interval --upgrade --cleanup --immediate
    echo "Brew autoupdate configured successfully!"
  fi

  printf "\n"
}

main() {
    if [[ ! -x "$DOTFILES_DIR/install.sh" ]]; then
        echo "Installer not found: $DOTFILES_DIR/install.sh"
        echo "Clone younsl/dotfiles to $DOTFILES_DIR first."
        exit 1
    fi

    print_plan
    prompt_user

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "=========================================="
        echo "Linking dotfiles ..."
        echo "=========================================="
        "$DOTFILES_DIR/install.sh"

        echo ""
        echo "=========================================="
        echo "Setting up pre-commit hooks ..."
        echo "=========================================="
        install_precommit
        if [[ -d "$ADDONS_DIR/.git" ]]; then
            (cd "$ADDONS_DIR" && pre-commit install)
        fi

        echo ""
        echo "=========================================="
        echo "Configuring brew autoupdate ..."
        echo "=========================================="
        configure_brew_autoupdate
    else
        echo "Operation cancelled."
    fi
}

main
