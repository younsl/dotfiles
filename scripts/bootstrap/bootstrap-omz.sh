#!/bin/bash

set -euo pipefail

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.oh-my-zsh"
ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR}/custom/plugins"

DOTFILES_DIR="$HOME/github/younsl/dotfiles/configs"
TARGET_DIR="$HOME"
LINK_NAME="zsh/.zshrc"

install_oh_my_zsh() {
    if [ ! -d "$OH_MY_ZSH_DIR" ]; then
        echo "현재 oh-my-zsh이 설치되어 있지 않습니다."
        echo "먼저 oh-my-zsh을 설치합니다."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "oh-my-zsh이 이미 설치되어 있습니다."
    fi
    echo ""
}

install_zsh_plugin() {
    local repo_url="$1"
    local target_dir="$2"

    if [ ! -d "$target_dir" ]; then
        if git clone --depth 1 "$repo_url" "$target_dir" 2>/dev/null; then
            echo "플러그인을 설치했습니다: $(basename "$target_dir")"
        else
            echo "플러그인 설치 실패: $(basename "$target_dir")" >&2
            return 1
        fi
    else
        echo "플러그인이 이미 설치되어 있습니다: $(basename "$target_dir")"
    fi
}

print_config() {
    echo ""
    echo "dotfiles_dir: $DOTFILES_DIR"
    echo "target_dir: $TARGET_DIR"
}

create_symbolic_link() {
    local source_path="$DOTFILES_DIR/$LINK_NAME"
    local link_path
    link_path="$TARGET_DIR/$(basename "$LINK_NAME")"

    if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "$source_path" ]; then
        echo "Symbolic link '$link_path' already points to '$source_path'. Skipping."
        return
    fi

    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        echo "'$link_path' already exists and is not the expected symbolic link."
        echo "Run scripts/bootstrap/bootstrap-dotfiles.sh instead; it backs up and replaces it safely."
        return
    fi

    ln -s "$source_path" "$link_path"
    echo "Symbolic link '$link_path' created."
}

main() {
    install_oh_my_zsh

    local plugins=(
        "https://github.com/zsh-users/zsh-autosuggestions.git|$ZSH_CUSTOM_PLUGINS_DIR/zsh-autosuggestions"
        "https://github.com/zdharma-continuum/fast-syntax-highlighting.git|$ZSH_CUSTOM_PLUGINS_DIR/fast-syntax-highlighting"
    )

    for plugin in "${plugins[@]}"; do
        local repo_url="${plugin%%|*}"
        local target_dir="${plugin#*|}"

        install_zsh_plugin "$repo_url" "$target_dir" || true
    done

    echo "zsh 플러그인 설치가 완료되었습니다."

    print_config
    create_symbolic_link
}

main
