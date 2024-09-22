#!/bin/bash

# 디렉토리 경로 설정
DOTFILES_DIR="${HOME}/github/younsl/dotfiles/vim"
TARGET_DIR="${HOME}/.vim"

# 현재 날짜와 시간 가져오기
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")

print_info() {
    echo "Current directory: $(pwd)"
    echo "Vim directory: ${DOTFILES_DIR}"
    echo "Target directory: ${TARGET_DIR}"
    echo "Current date and time: ${CURRENT_DATE}"
}

backup_existing_dir() {
    if [ -d "${TARGET_DIR}" ]; then
        echo ".vim 디렉토리가 이미 존재합니다."
        echo "기존 .vim 디렉토리의 백업을 생성합니다."
        mv "${TARGET_DIR}" "${TARGET_DIR}.$(date +%Y%m%d_%H%M%S).bak"
    fi
}

create_symlink() {
    ln -s ${DOTFILES_DIR} ${TARGET_DIR}
    if [ $? -eq 0 ]; then
        echo "심볼릭 링크가 성공적으로 생성되었습니다."
        echo "${DOTFILES_DIR} -> ${TARGET_DIR}"
    else
        echo "심볼릭 링크 생성에 실패했습니다."
        exit 1
    fi
}

main() {
    print_info
    backup_existing_dir
    create_symlink
    echo "Vim 설정이 완료되었습니다. (설정 시간: ${CURRENT_DATE})"
}

main
