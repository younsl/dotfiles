#!/bin/zsh

DOTFILES_DIR="$HOME/github/younsl/dotfiles/configs"

COMPONENTS=(
    "fortune:$HOME/.config/fortune"
    "git:$HOME/.config/git"
    "k9s:$HOME/.config/k9s"
    "ghostty:$HOME/.config/ghostty"
    "nvim:$HOME/.config/nvim"
    "pip:$HOME/.config/pip"
    "zshrc:$HOME/.zshrc"
    "zsh/functions:$HOME/.config/zsh/functions"
    "fastfetch:$HOME/.config/fastfetch"
    "gnupg/gpg.conf:$HOME/.gnupg/gpg.conf"
    "gnupg/gpg-agent.conf:$HOME/.gnupg/gpg-agent.conf"
    "gnupg/common.conf:$HOME/.gnupg/common.conf"
    "claude/settings.json:$HOME/.claude/settings.json"
    "claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
    "claude/skills:$HOME/.claude/skills"
    "claude/hooks:$HOME/.claude/hooks"
)

print_symlinks() {
    echo "The following symbolic links will be created:"
    local index=1
    for entry in "${COMPONENTS[@]}"; do
        COMPONENT="${entry%%:*}"
        TARGET_DIR="${entry#*:}"

        if [[ "$COMPONENT" == "zshrc" ]]; then
            COMPONENT_PATH="$DOTFILES_DIR/zsh/.zshrc"
        else
            COMPONENT_PATH="$DOTFILES_DIR/$COMPONENT"
        fi

        if [[ -e "$COMPONENT_PATH" ]]; then
            echo "$index: $TARGET_DIR -> $COMPONENT_PATH"
        else
            echo "$index: Does not exist: $COMPONENT_PATH"
        fi
        ((index++))
    done
}

create_symlinks() {
    mkdir -p "$HOME/.config"

    for entry in "${COMPONENTS[@]}"; do
        COMPONENT="${entry%%:*}"
        TARGET_DIR="${entry#*:}"

        if [[ "$COMPONENT" == "zshrc" ]]; then
            COMPONENT_PATH="$DOTFILES_DIR/zsh/.zshrc"
        else
            COMPONENT_PATH="$DOTFILES_DIR/$COMPONENT"
        fi

        # Ensure the parent directory of the target symlink exists
        TARGET_PARENT_DIR=$(dirname "$TARGET_DIR")
        mkdir -p "$TARGET_PARENT_DIR"

        if [[ -d "$COMPONENT_PATH" ]]; then
            rm -rf "$TARGET_DIR"
            ln -sf "$COMPONENT_PATH" "$TARGET_DIR"
            echo "$TARGET_DIR -> $COMPONENT_PATH (Symbolic link created as directory)"

        elif [[ -f "$COMPONENT_PATH" ]]; then
            rm -f "$TARGET_DIR"
            ln -sf "$COMPONENT_PATH" "$TARGET_DIR"
            echo "$TARGET_DIR -> $COMPONENT_PATH (Symbolic link created as file)"

        else
            echo "Does not exist: $COMPONENT_PATH"
        fi
    done
}

prompt_user() {
    read -p "Do you want to proceed with this action? (yY/n): " REPLY
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
  # Check if brew is installed
  if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed. Skipping brew autoupdate configuration."
    printf "\n"
    return
  fi

  local autoupdate_interval=86400
  
  echo "Configuring brew autoupdate ..."
  
  # Install homebrew-autoupdate tap if not already installed
  if ! brew tap | grep -q "homebrew/autoupdate"; then
    echo "Installing homebrew/autoupdate tap ..."
    brew tap homebrew/autoupdate
  else
    echo "homebrew/autoupdate tap is already installed."
  fi
  
  # Check current autoupdate status
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
    print_symlinks
    prompt_user

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "=========================================="
        echo "Setting up symbolic links ..."
        echo "=========================================="
        create_symlinks
        echo "Symbolic links created successfully!"
        
        echo ""
        echo "=========================================="
        echo "Setting up pre-commit hooks ..."
        echo "=========================================="
        install_precommit
        pre-commit install
        
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
