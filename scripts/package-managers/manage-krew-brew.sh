#!/bin/bash

set -euo pipefail

BREW_DIR="$HOME/github/younsl/dotfiles/configs/brew"
KREW_DIR="$HOME/github/younsl/dotfiles/configs/krew"
BACKUP_FILE="$KREW_DIR/Krewfile"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

check_kubectl_and_krew() {
    if ! command -v kubectl &> /dev/null; then
        echo "[e] kubectl command not found. Please ensure kubectl is installed."
        exit 1
    fi

    if ! kubectl krew &> /dev/null; then
        echo "[e] kubectl krew command not found. Please install krew."
        exit 1
    fi
}

backup_krewfile() {
    check_kubectl_and_krew

    local today_date
    local krew_version
    today_date=$(date +%Y-%m-%d)
    krew_version=$(kubectl krew version | grep GitTag | awk '{print $2}')

    {
        echo "#---------------------------------"
        echo "# Backup completed on $today_date "
        echo "# Krew version is $krew_version   "
        echo "#---------------------------------"
        kubectl krew list
    } | tee "$BACKUP_FILE"

    echo "[i] Krew list backed up to $BACKUP_FILE"
}

restore_krewfile() {
    check_kubectl_and_krew

    if [ -f "$BACKUP_FILE" ]; then
        grep -v "^#" "$BACKUP_FILE" | kubectl krew install
        echo "[i] Krew list restored from backup."
    else
        echo "[e] Backup file not found: $BACKUP_FILE"
        exit 1
    fi
}

prompt_for_filename() {
    read -r -p "$(printf "%bEnter the name for the Brewfile (default: Brewfile): %b" "$GREEN" "$NC")" file_name
    file_name=${file_name:-Brewfile}
}

confirm_overwrite() {
    if [[ -f "$1" ]]; then
        read -r -p "$(printf "%bFile '%s' already exists. Overwrite? (y/N): %b" "$GREEN" "$1" "$NC")" overwrite
        if [[ $overwrite =~ ^[Yy]$ ]]; then
            rm -f "$1"
        else
            printf "%bOperation cancelled.%b\n" "$YELLOW" "$NC"
            exit 1
        fi
    fi
}

create_brewfile() {
    confirm_overwrite "$1"
    brew cleanup
    if brew bundle dump --file="$1"; then
        printf "%bBrewfile created successfully: %b%s\n" "$GREEN" "$NC" "$1"
        append_summary "$1"
    else
        printf "%bError creating Brewfile.%b\n" "$YELLOW" "$NC"
        exit 1
    fi
}

append_summary() {
    local sections=("tap" "brew" "cask" "mas" "vscode")
    local today
    today=$(date +%Y-%m-%d)

    {
        echo "#-------------------------------"
        echo "# PACKAGE INSTALLATION SUMMARY"
        echo "# Date: $today"
        echo "#-------------------------------"

        local section
        local count
        for section in "${sections[@]}"; do
            count=$(grep -c "^$section " "$1" || true)
            echo "# Installed $section count: $count"
        done

        echo "#-------------------------------"
    } >> "$1"
}

get_user_choice() {
    read -r -p "Choose an action (1: Backup krew, 2: Restore krew, 3: Create Brewfile): " choice
    echo "$choice"
}

main() {
    echo "Backup or restore krew list, or create a Brewfile."
    local choice
    choice=$(get_user_choice)

    case "$choice" in
        1)
            backup_krewfile
            ;;
        2)
            restore_krewfile
            ;;
        3)
            prompt_for_filename
            create_brewfile "$BREW_DIR/$file_name"
            ;;
        *)
            echo "[e] Invalid choice. Exiting script."
            exit 1
            ;;
    esac
}

main
