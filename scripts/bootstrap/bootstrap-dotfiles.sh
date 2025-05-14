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
    "fastfetch:$HOME/.config/fastfetch"
    "ol:$HOME/.config/ol"
    "gnupg/gpg.conf:$HOME/.gnupg/gpg.conf"
    "gnupg/gpg-agent.conf:$HOME/.gnupg/gpg-agent.conf"
    "gnupg/common.conf:$HOME/.gnupg/common.conf"
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
    echo "pre-commit not found. Installing via Homebrew..."
    brew install pre-commit
  else
    echo "pre-commit is already installed."
    pre_commit_version=$(pre-commit --version)
    echo "pre-commit version: $pre_commit_version"
  fi

  printf "\n"
}

main() {
    print_symlinks
    prompt_user

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_symlinks
        echo "Symbolic links created successfully!"
    else
        echo "Operation cancelled."
    fi

    install_precommit
    pre-commit install
}

main
