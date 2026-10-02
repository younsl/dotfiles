#!/bin/zsh

set -euo pipefail

DOTFILES_DIR="$HOME/github/younsl/dotfiles/configs"

BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR=""
REPLY=""

COMPONENTS=(
    "git:$HOME/.config/git"
    "k9s:$HOME/.config/k9s"
    "ghostty:$HOME/.config/ghostty"
    "nvim:$HOME/.config/nvim"
    "pip:$HOME/.config/pip"
    "mise:$HOME/.config/mise"
    "zshrc:$HOME/.zshrc"
    "zsh/functions:$HOME/.config/zsh/functions"
    "gnupg/gpg.conf:$HOME/.gnupg/gpg.conf"
    "gnupg/gpg-agent.conf:$HOME/.gnupg/gpg-agent.conf"
    "gnupg/common.conf:$HOME/.gnupg/common.conf"
    "claude/settings.json:$HOME/.claude/settings.json"
    "claude/AGENTS.md:$HOME/.claude/CLAUDE.md"
    "skills:$HOME/.claude/skills"
    "claude/hooks:$HOME/.claude/hooks"
    "claude/scripts:$HOME/.claude/scripts"
)

backup_target() {
    local target="$1"
    local dest

    if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
    fi

    dest="$BACKUP_DIR/${target#$HOME/}"
    mkdir -p "$(dirname "$dest")"
    mv "$target" "$dest"
    echo "Backed up: $target -> $dest"
}

link_component() {
    local source_path="$1"
    local target="$2"
    local kind="$3"

    if [[ -L "$target" ]]; then
        if [[ "$(readlink "$target")" == "$source_path" ]]; then
            echo "$target -> $source_path (Already linked, skipped)"
            return
        fi
        rm -f "$target"
    elif [[ -e "$target" ]]; then
        backup_target "$target"
    fi

    ln -s "$source_path" "$target"
    echo "$target -> $source_path (Symbolic link created as $kind)"
}

print_symlinks() {
    setopt local_options null_glob

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

        if [[ "$COMPONENT" == "skills" && -d "$COMPONENT_PATH" ]]; then
            echo "$index: $TARGET_DIR/* -> $COMPONENT_PATH/* (per-skill links; keeps Claude-managed entries in place)"
        elif [[ -e "$COMPONENT_PATH" ]]; then
            echo "$index: $TARGET_DIR -> $COMPONENT_PATH"
        else
            echo "$index: Does not exist: $COMPONENT_PATH"
        fi
        index=$((index + 1))
    done
}

create_symlinks() {
    setopt local_options null_glob

    mkdir -p "$HOME/.config"

    for entry in "${COMPONENTS[@]}"; do
        COMPONENT="${entry%%:*}"
        TARGET_DIR="${entry#*:}"

        if [[ "$COMPONENT" == "zshrc" ]]; then
            COMPONENT_PATH="$DOTFILES_DIR/zsh/.zshrc"
        else
            COMPONENT_PATH="$DOTFILES_DIR/$COMPONENT"
        fi

        TARGET_PARENT_DIR=$(dirname "$TARGET_DIR")
        mkdir -p "$TARGET_PARENT_DIR"

        if [[ "$COMPONENT" == "skills" && -d "$COMPONENT_PATH" ]]; then
            if [[ -L "$TARGET_DIR" ]]; then
                rm -f "$TARGET_DIR"
            fi
            mkdir -p "$TARGET_DIR"

            for SKILL_PATH in "$COMPONENT_PATH"/*; do
                [[ -d "$SKILL_PATH" ]] || continue
                SKILL_NAME=$(basename "$SKILL_PATH")
                TARGET_SKILL_DIR="$TARGET_DIR/$SKILL_NAME"

                link_component "$SKILL_PATH" "$TARGET_SKILL_DIR" "directory"
            done

        elif [[ -d "$COMPONENT_PATH" ]]; then
            link_component "$COMPONENT_PATH" "$TARGET_DIR" "directory"

        elif [[ -f "$COMPONENT_PATH" ]]; then
            link_component "$COMPONENT_PATH" "$TARGET_DIR" "file"

        else
            echo "Does not exist: $COMPONENT_PATH"
        fi
    done
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
