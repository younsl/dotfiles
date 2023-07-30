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

# 파일명을 입력받는 함수
prompt_for_filename() {
    # 현재 날짜를 YYYYMMDD 형식으로 가져옵니다.
    local current_date=$(date +"%Y%m%d")

    read -p "생성할 Bundle 파일의 이름을 입력하세요 (기본값: $current_date.Brewfile): " file_name

    # 파일명이 비어있으면 기본적으로 현재 날짜를 사용합니다.
    if [[ -z $file_name ]]; then
        file_name="$current_date.Brewfile"
    fi
}

# Brewfile을 생성하는 함수
create_brewfile() {
    local file_name="$1"
    if brew bundle dump --describe --file "$file_name"; then
        echo "Brewfile이 성공적으로 생성되었습니다."
        echo "파일명: $file_name"

        # brew, cask, tap 개수 출력
        brew_count=$(grep -c "brew " "$file_name")
        cask_count=$(grep -c "cask " "$file_name")
        tap_count=$(grep -c "tap " "$file_name")
        mas_count=$(grep -c "mas " "$file_name")
        vscode_count=$(grep -c "vscode " "$file_name")

        # 섹션별 개수 계산 및 출력
        print_section_counts() {
            local sections=("tap" "brew" "cask" "mas" "vscode")

            echo "#--------------------------------------"
            echo "# Package installation summary"
            echo "#--------------------------------------"
            for section in "${sections[@]}";
            do
                count=$(grep -c "$section " "$file_name")
                echo "# Installed $section count: $count"
            done
            echo "#--------------------------------------"
        }

        print_section_counts | tee -a "$file_name"
    else
        echo "Brewfile 생성 중 오류가 발생했습니다."
    fi
}

# 메인 함수
main() {
    # 파일명을 입력받습니다.
    prompt_for_filename

    # Brewfile 생성 함수 호출
    create_brewfile "$file_name"
}

# 메인 함수 호출
main
