#!/bin/bash

set -euo pipefail

GITHUB_USERNAME="younsl"
GITHUB_API_URL="https://api.github.com/users/${GITHUB_USERNAME}/repos"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

create_directory() {
    local path=$1
    if [ ! -d "$path" ]; then
        printf "%bCreating directory: %b%s\n" "$GREEN" "$NC" "$path"
        mkdir -p "$path"
    fi
}

fetch_repos_data() {
    local url=$1
    curl -sf "$url"
}

display_repos() {
    local repos_data=$1
    local repo_count

    repo_count=$(echo "$repos_data" | jq '. | length')
    printf "%bTotal %s repositories found.%b\n" "$GREEN" "$repo_count" "$NC"
    printf "%bRepository list:%b\n" "$GREEN" "$NC"

    echo "$repos_data" | jq -r '
        .[] | {
            number: 1,
            name: .name,
            description: (.description // "No description")
        } | [.name, .description] | @tsv
    ' | \
    awk '
        { printf "%-2d  %-30s  %s\n",
            NR,
            $1,
            substr($0, index($0,$2))
        }
    '
}

clone_repository() {
    local repo_url=$1
    local repo_name=$2
    local clone_path=$3
    git clone "$repo_url" "$clone_path/$repo_name"
}

clone_all_repos() {
    local repos_data=$1
    local clone_path=$2
    local row
    local repo_url
    local repo_name

    for row in $(echo "$repos_data" | jq -r '.[] | @base64'); do
        repo_url=$(echo "$row" | base64 --decode | jq -r '.clone_url')
        repo_name=$(echo "$row" | base64 --decode | jq -r '.name')
        clone_repository "$repo_url" "$repo_name" "$clone_path"
    done
}

main() {
    local clone_path
    local repos_data
    local response

    read -r -p "$(printf "%bEnter the path to clone repositories: %b" "$GREEN" "$NC")" clone_path
    create_directory "$clone_path"

    repos_data=$(fetch_repos_data "$GITHUB_API_URL")
    display_repos "$repos_data"

    read -r -p "$(printf "%bDo you want to proceed with cloning all these repositories? (Y/n) %b" "$GREEN" "$NC")" response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        printf "%bCloning repositories...%b\n" "$GREEN" "$NC"
        clone_all_repos "$repos_data" "$clone_path"
        printf "%bCloning completed!%b\n" "$GREEN" "$NC"
    else
        printf "%bCloning canceled by user.%b\n" "$YELLOW" "$NC"
    fi
}

main
