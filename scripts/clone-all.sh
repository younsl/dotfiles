#!/bin/bash

# 사용자명
github_username="younsl"

# GitHub API의 엔드포인트
api_url="https://api.github.com/users/${github_username}/repos"

# ANSI 색상 코드
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 폴더 생성 함수
create_directory() {
    local path=$1
    if [ ! -d "$path" ]; then
        echo "${GREEN}Creating directory: ${NC}$path"
        mkdir -p "$path"
    fi
}

# 레포지토리 데이터 가져오기 함수
fetch_repos_data() {
    local url=$1
    echo $(curl -s "$url")
}

# 레포지토리 개수 및 목록 출력 함수
display_repos() {
    local repos_data=$1
    local repo_count=$(echo "$repos_data" | jq '. | length')
    echo "${GREEN}Total $repo_count repositories found.${NC}"
    echo "${GREEN}Repository list:${NC}"
    echo "$repos_data" | jq -r '.[].name' | nl
}

# 레포지토리 클론 함수
clone_repository() {
    local repo_url=$1
    local repo_name=$2
    local clone_path=$3
    git clone "$repo_url" "$clone_path/$repo_name"
}

# 모든 레포지토리 클론
clone_all_repos() {
    local repos_data=$1
    local clone_path=$2
    for row in $(echo "$repos_data" | jq -r '.[] | @base64'); do
        local repo_url=$(echo ${row} | base64 --decode | jq -r '.clone_url')
        local repo_name=$(echo ${row} | base64 --decode | jq -r '.name')
        clone_repository "$repo_url" "$repo_name" "$clone_path"
    done
}

# 메인 스크립트 실행
main() {
    read -p "$(echo "${GREEN}Enter the path to clone repositories: ${NC}")" clone_path
    create_directory "$clone_path"
    local repos_data=$(fetch_repos_data "$api_url")
    display_repos "$repos_data"
    read -p "$(echo "${GREEN}Do you want to proceed with cloning all these repositories? (Y/n) ${NC}")" response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "${GREEN}Cloning repositories...${NC}"
        clone_all_repos "$repos_data" "$clone_path"
        echo "${GREEN}Cloning completed!${NC}"
    else
        echo "${YELLOW}Cloning canceled by user.${NC}"
    fi
}

main
