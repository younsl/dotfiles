#!/bin/bash

# Environment variables for Github Cloud API
GITHUB_USERNAME="younsl"
GITHUB_API_URL="https://api.github.com/users/${GITHUB_USERNAME}/repos"

# Environment variables for colorized output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

#-------------------------------------------
# Functions
#-------------------------------------------
create_directory() {
    local path=$1
    if [ ! -d "$path" ]; then
        echo "${GREEN}Creating directory: ${NC}$path"
        mkdir -p "$path"
    fi
}

fetch_repos_data() {
    local url=$1
    echo $(curl -s "$url")
}

display_repos() {
    local repos_data=$1
    
    local repo_count=$(echo "$repos_data" | jq '. | length')
    echo "${GREEN}Total $repo_count repositories found.${NC}"
    echo "${GREEN}Repository list:${NC}"
    
    echo "$repos_data" | jq -r '
        .[] | {
            number: 1,
            name: .name,
            description: (.description // "No description")
        } | [.name, .description] | @tsv
    ' | \
    awk '
        { printf "%-2d  %-30s  %s\n",
            NR,                       # Number
            $1,                       # Repository Name
            substr($0, index($0,$2))  # Description
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
    for row in $(echo "$repos_data" | jq -r '.[] | @base64'); do
        local repo_url=$(echo ${row} | base64 --decode | jq -r '.clone_url')
        local repo_name=$(echo ${row} | base64 --decode | jq -r '.name')
        clone_repository "$repo_url" "$repo_name" "$clone_path"
    done
}

#-------------------------------------------
# Main
#-------------------------------------------
main() {
    read -p "$(echo "${GREEN}Enter the path to clone repositories: ${NC}")" clone_path
    create_directory "$clone_path"
    local repos_data=$(fetch_repos_data "$GITHUB_API_URL")
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
