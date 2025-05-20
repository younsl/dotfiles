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

# Set environment variables
BREW_DIR="$HOME/github/younsl/dotfiles/configs/brew"
KREW_DIR="$HOME/github/younsl/dotfiles/configs/krew"
BACKUP_FILE="$KREW_DIR/Krewfile"

# ANSI color codes
GREEN='[0;32m'
YELLOW='[0;33m'
NC='[0m' # No Color

# Function to check if kubectl and kubectl krew are installed
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

# Function to backup krew list
backup_krewfile() {
    check_kubectl_and_krew

    local today_date=$(date +%Y-%m-%d)
    local krew_version=$(kubectl krew version | grep GitTag | awk '{print $2}')

    {
        echo "#---------------------------------"
        echo "# Backup completed on $today_date "
        echo "# Krew version is $krew_version   "
        echo "#---------------------------------"
        kubectl krew list
    } | tee "$BACKUP_FILE"

    echo "[i] Krew list backed up to $BACKUP_FILE"
}

# Function to restore krew list
restore_krewfile() {
    check_kubectl_and_krew

    if [ -f "$BACKUP_FILE" ]; then
        grep -v "^#" "$BACKUP_FILE" | kubectl krew install
        echo "[i] Krew list restored from backup."
    else
        echo "[e] Backup file not found: $BACKUP_FILE"
    fi
}

# Function to prompt for filename
prompt_for_filename() {
    read -p "$(echo "${GREEN}Enter the name for the Brewfile (default: Brewfile): ${NC}")" file_name
    file_name=${file_name:-Brewfile}
}

# Confirm file overwrite
confirm_overwrite() {
    if [[ -f "$1" ]]; then
        read -p "$(echo "${GREEN}File '$1' already exists. Overwrite? (y/N): ${NC}")" overwrite
        if [[ $overwrite =~ ^[Yy]$ ]]; then
            rm -f "$1"
        else
            echo "${YELLOW}Operation cancelled.${NC}"
            exit 1
        fi
    fi
}

# Create Brewfile
create_brewfile() {
    confirm_overwrite "$1"
    brew cleanup
    if brew bundle dump --describe --file="$1"; then
        echo "${GREEN}Brewfile created successfully: ${NC}$1"
        append_summary "$1"
    else
        echo "${YELLOW}Error creating Brewfile.${NC}"
    fi
}

# Calculate and append section counts
append_summary() {
    local sections=("tap" "brew" "cask" "mas" "vscode")
    local today=$(date +%Y-%m-%d)
    echo "#-------------------------------" >> "$1"
    echo "# PACKAGE INSTALLATION SUMMARY" >> "$1"
    echo "# Date: $today" >> "$1"
    echo "#-------------------------------" >> "$1"

    for section in "${sections[@]}"; do
        local count=$(grep -c "$section " "$1")
        echo "# Installed $section count: $count" >> "$1"
    done

    echo "#-------------------------------" >> "$1"
}

# Function to get user choice
get_user_choice() {
    read -p "Choose an action (1: Backup krew, 2: Restore krew, 3: Create Brewfile): " choice
    echo "$choice"
}

# Main function
main() {
    echo "Backup or restore krew list, or create a Brewfile."
    local choice=$(get_user_choice)

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

# Call main function
main
