#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$DOTFILES_DIR/configs"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

LINKS=(
    "git:.config/git"
    "k9s:.config/k9s"
    "ghostty:.config/ghostty"
    "nvim:.config/nvim"
    "package-managers/pip:.config/pip"
    "package-managers/uv:.config/uv"
    "package-managers/npm/.npmrc:.npmrc"
    "package-managers/pnpm/config.yaml:.config/pnpm/config.yaml"
    "package-managers/yarn/.yarnrc:.yarnrc"
    "package-managers/mise:.config/mise"
    "zsh/.zshrc:.zshrc"
    "zsh/functions:.config/zsh/functions"
    "gnupg/gpg.conf:.gnupg/gpg.conf"
    "gnupg/gpg-agent.conf:.gnupg/gpg-agent.conf"
    "gnupg/common.conf:.gnupg/common.conf"
    "claude/settings.json:.claude/settings.json"
    "claude/AGENTS.md:.claude/CLAUDE.md"
    "claude/hooks:.claude/hooks"
)

PER_ENTRY_LINKS=(
    "claude/skills:.claude/skills"
)

usage() {
    cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [-h|--help]

Symlink dotfiles from $CONFIGS_DIR into $HOME.
Real files in the way are moved to $HOME/.dotfiles-backup/TIMESTAMP/.
EOF
}

run() {
    if [[ $DRY_RUN == true ]]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

link() {
    local source="$1"
    local target="$2"

    if [[ ! -e $source ]]; then
        echo "[skip] missing source: $source"
        return
    fi

    if [[ -L $target && "$(readlink "$target")" == "$source" ]]; then
        echo "[ok] $target"
        return
    fi

    if [[ -e $target && ! -L $target ]]; then
        local backup="$BACKUP_DIR/${target#"$HOME"/}"
        run mkdir -p "$(dirname "$backup")"
        run mv "$target" "$backup"
        echo "[backup] $target -> $backup"
    fi

    run mkdir -p "$(dirname "$target")"
    run ln -sfn "$source" "$target"
    echo "[link] $target -> $source"
}

prune_dangling() {
    local dir="$1"
    local entry

    [[ -d $dir ]] || return 0

    for entry in "$dir"/*; do
        if [[ -L $entry && ! -e $entry ]]; then
            run rm "$entry"
            echo "[prune] $entry"
        fi
    done
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=true ;;
            -h|--help) usage; exit 0 ;;
            *) usage; exit 1 ;;
        esac
        shift
    done

    if [[ ! -d $HOME/.gnupg ]]; then
        run mkdir -m 700 "$HOME/.gnupg"
    fi

    local pair source target entry
    for pair in "${LINKS[@]}"; do
        source="${pair%%:*}"
        target="${pair#*:}"
        link "$CONFIGS_DIR/$source" "$HOME/$target"
    done

    for pair in "${PER_ENTRY_LINKS[@]}"; do
        source="${pair%%:*}"
        target="${pair#*:}"
        if [[ -L $HOME/$target ]]; then
            run rm "$HOME/$target"
        fi
        run mkdir -p "$HOME/$target"
        for entry in "$CONFIGS_DIR/$source"/*/; do
            entry="${entry%/}"
            link "$entry" "$HOME/$target/$(basename "$entry")"
        done
        prune_dangling "$HOME/$target"
    done
}

main "$@"
