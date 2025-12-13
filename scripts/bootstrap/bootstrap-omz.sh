#!/bin/bash

#------------------------------------------------------------------------
#
# 888                     888           888
# 888                     888           888
# 888                     888           888
# 88888b.  .d88b.  .d88b. 888888.d8888b 888888888d888 8888b. 88888b.
# 888 "88bd88""88bd88""88b888   88K     888   888P"      "88b888 "88b
# 888  888888  888888  888888   "Y8888b.888   888    .d888888888  888
# 888 d88PY88..88PY88..88PY88b.      X88Y88b. 888    888  888888 d88P
# 88888P"  "Y88P"  "Y88P"  "Y888 88888P' "Y888888    "Y88888888888P"
#                                                            888
#                                                           888
#                                                           888
#
#------------------------------------------------------------------------

# Oh My Zsh configuration
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.oh-my-zsh"
ZSH_CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR}/custom/plugins"

# Dotfiles configuration
DOTFILES_DIR="$HOME/github/younsl/dotfiles/configs"
TARGET_DIR="$HOME"
LINK_NAME="zsh/.zshrc"


# Function: Install oh-my-zsh
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


# Function: Install zsh plugins
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


# Function: Print configuration details
print_config() {
    echo ""
    echo "dotfiles_dir: $DOTFILES_DIR"
    echo "target_dir: $TARGET_DIR"
}


# Function: Create symbolic link
create_symbolic_link() {
    local link_path="$TARGET_DIR/$LINK_NAME"

    if [ -L "$link_path" ]; then
        echo "Symbolic link '$LINK_NAME' already exists in '$TARGET_DIR'."
        echo "Skipping."
    else
        ln -s "$DOTFILES_DIR/$LINK_NAME" "$TARGET_DIR"
        echo "Symbolic link '$LINK_NAME' created in '$TARGET_DIR'."
    fi
}


# Main function
main() {
    install_oh_my_zsh

    local plugins=(
        "https://github.com/zsh-users/zsh-autosuggestions.git|$ZSH_CUSTOM_PLUGINS_DIR/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-syntax-highlighting.git|$ZSH_CUSTOM_PLUGINS_DIR/zsh-syntax-highlighting"
        "https://github.com/zdharma-continuum/fast-syntax-highlighting.git|$ZSH_CUSTOM_PLUGINS_DIR/fast-syntax-highlighting"
        "https://github.com/marlonrichert/zsh-autocomplete.git|$ZSH_CUSTOM_PLUGINS_DIR/zsh-autocomplete"
    )

    for plugin in "${plugins[@]}"; do
        local repo_url=$(echo "$plugin" | cut -d '|' -f 1)
        local target_dir=$(echo "$plugin" | cut -d '|' -f 2)

        install_zsh_plugin "$repo_url" "$target_dir"
    done

    echo "zsh 플러그인 설치가 완료되었습니다."

    print_config
    create_symbolic_link
}

# Invoke main function
main
