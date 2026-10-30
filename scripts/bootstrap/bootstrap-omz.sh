#!/bin/bash

set -euo pipefail

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.oh-my-zsh"
ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR}/custom/plugins"

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
}

main
