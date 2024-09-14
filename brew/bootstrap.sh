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

# ANSI 색상 코드
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 파일명을 입력받는 함수
prompt_for_filename() {
    read -p "$(echo "${GREEN}생성할 Bundle 파일의 이름을 입력하세요 (기본값: Brewfile): ${NC}")" file_name
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

main() {
    prompt_for_filename
    create_brewfile "$file_name"
}

main