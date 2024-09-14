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

# 백업 파일명 환경변수
BACKUP_FILE="krewfile"


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


# 사용자 입력을 받는 함수
get_user_choice() {
    read -p "작업을 선택하세요 (1 또는 2): " choice
    echo "$choice"
}


# 메인 함수
main() {
    echo "krew 리스트를 백업하거나 복구할 수 있습니다."
    echo "  1. krew 리스트 백업"
    echo "  2. krew 리스트 복구"

    local choice=$(get_user_choice)

    case "$choice" in
        1)
            backup_krewfile
            ;;
        2)
            restore_krewfile
            ;;
        *)
            echo "[e] 올바른 선택을 입력하지 않아 스크립트를 종료합니다."
            exit 1
            ;;
    esac
}

# 메인 함수 호출
main
