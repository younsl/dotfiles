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

# 현재 날짜를 YYYYMMDD 형식으로 가져옵니다.
current_date=$(date +"%Y%m%d")

# 파일명을 입력받는 함수
prompt_for_filename() {
    read -p "생성할 Bundle 파일의 이름을 입력하세요
(기본값: $current_date.Brewfile): " file_name

    # 파일명이 비어있으면 기본적으로 현재 날짜를 사용합니다.
    if [[ -z $file_name ]]; then
        file_name="$current_date.Brewfile"
    fi
}

# 파일명을 입력받습니다.
prompt_for_filename

# bundle dump 명령어를 실행하여 Bundle 파일을 생성합니다.
if brew bundle dump --describe --file "$file_name"; then
    echo "Bundle 파일이 성공적으로 생성되었습니다."
    echo "파일명: $file_name"
else
    echo "Bundle 파일 생성 중 오류가 발생했습니다."
fi