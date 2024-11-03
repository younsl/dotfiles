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

# 환경변수 설정
BREW_DIR="$HOME/github/younsl/dotfiles/configs/brew"
KREW_DIR="$HOME/github/younsl/dotfiles/configs/krew"
BACKUP_FILE="$KREW_DIR/Krewfile"

# ANSI 색상 코드
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# kubectl과 kubectl krew 명령어의 설치 여부를 확인하는 함수
check_kubectl_and_krew() {
    if ! command -v kubectl &> /dev/null; then
        echo "[e] kubectl 명령어를 찾을 수 없습니다. kubectl이 설치되어 있는지 확인하세요."
        exit 1
    fi

    if ! kubectl krew &> /dev/null; then
        echo "[e] kubectl krew 명령어를 찾을 수 없습니다. krew를 설치해주세요."
        exit 1
    fi
}

# krew 리스트를 백업하는 함수
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

    echo "[i] krew 리스트를 백업했습니다. ($BACKUP_FILE)"
}

# krew 리스트를 복구하는 함수
restore_krewfile() {
    check_kubectl_and_krew

    if [ -f "$BACKUP_FILE" ]; then
        grep -v "^#" "$BACKUP_FILE" | kubectl krew install
        echo "[i] krew 리스트를 복구했습니다."
    else
        echo "[e] 백업 파일을 찾을 수 없습니다."
    fi
}

# 파일명을 입력받는 함수
prompt_for_filename() {
    read -p "$(echo "${GREEN}생성할 Brewfile의 이름을 입력하세요 (기본값: Brewfile): ${NC}")" file_name
    file_name=${file_name:-Brewfile}
}

# 기존 파일 덮어쓰기 확인
confirm_overwrite() {
    if [[ -f "$1" ]]; then
        read -p "$(echo "${GREEN}파일 '$1'이(가) 이미 존재합니다. 덮어쓰시겠습니까? (y/N): ${NC}")" overwrite
        if [[ $overwrite =~ ^[Yy]$ ]]; then
            rm -f "$1"
        else
            echo "${YELLOW}작업이 취소되었습니다.${NC}"
            exit 1
        fi
    fi
}

# Brewfile 생성
create_brewfile() {
    confirm_overwrite "$1"
    if brew bundle dump --describe --file="$1"; then
        echo "${GREEN}Brewfile이 성공적으로 생성되었습니다. 파일명: ${NC}$1"
        append_summary "$1"
    else
        echo "${YELLOW}Brewfile 생성 중 오류가 발생했습니다.${NC}"
    fi
}

# 섹션별 개수 계산 및 출력
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

# 사용자 입력을 받는 함수
get_user_choice() {
    read -p "작업을 선택하세요 (1: krew 백업, 2: krew 복구, 3: Brewfile 생성): " choice
    echo "$choice"
}

# 메인 함수
main() {
    echo "krew 리스트를 백업하거나 복구하거나 Brewfile을 생성할 수 있습니다."
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
            echo "[e] 올바른 선택을 입력하지 않아 스크립트를 종료합니다."
            exit 1
            ;;
    esac
}

# 메인 함수 호출
main
