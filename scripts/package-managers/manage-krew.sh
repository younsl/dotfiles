#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KREWFILE="$REPO_DIR/configs/package-managers/krew/krewfile"

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
    } | tee "$KREWFILE"

    echo "[i] Krew list backed up to $KREWFILE"
}

restore_krewfile() {
    check_kubectl_and_krew

    if [ -f "$KREWFILE" ]; then
        grep -v "^#" "$KREWFILE" | kubectl krew install
        echo "[i] Krew list restored from backup."
    else
        echo "[e] Backup file not found: $KREWFILE"
        exit 1
    fi
}

main() {
    local choice
    read -r -p "Choose an action (1: Backup krew, 2: Restore krew): " choice

    case "$choice" in
        1) backup_krewfile ;;
        2) restore_krewfile ;;
        *)
            echo "[e] Invalid choice. Exiting script."
            exit 1
            ;;
    esac
}

main
