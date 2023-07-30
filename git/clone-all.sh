#!/bin/bash

# 사용자명
github_username="younsl"

# GitHub API의 엔드포인트
api_url="https://api.github.com/users/${github_username}/repos"

# 레포지토리를 클론할 경로를 입력 받음
read -p "Enter the path to clone repositories: " clone_path

# 입력된 경로가 존재하지 않으면 디렉토리를 생성
if [ ! -d "$clone_path" ]; then
    echo "Creating directory: $clone_path"
    mkdir -p "$clone_path"
fi

# API를 호출하여 JSON 응답 받기
repos_data=$(curl -s "${api_url}")

# 레포지토리를 클론하는 함수
function clone_repository {
    local repo_url=$1
    local repo_name=$2
    git clone "${repo_url}" "${clone_path}/${repo_name}"
}

# 모든 레포지토리를 클론하기
echo "Cloning repositories..."
for row in $(echo "${repos_data}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    repo_url=$(_jq '.clone_url')
    repo_name=$(_jq '.name')
    clone_repository "${repo_url}" "${repo_name}"
done

echo "Cloning completed!"
