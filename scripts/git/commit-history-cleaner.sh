#!/bin/bash

set -euo pipefail

change_to_git_root() {
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [[ -z "$git_root" ]]; then
        echo "Error: Not inside a git repository."
        exit 1
    fi
    cd "$git_root" || exit 1
    echo "Working in git root: $git_root"
}

command_exists() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' command is not installed."
        exit 1
    fi
}

confirm_action() {
    local prompt_message=$1
    REPLY=""
    read -r -n 1 -p "$prompt_message (yY/n) " || true
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation canceled by user."
        exit 1
    fi
}

initialize_new_branch() {
    local branch_name=$1
    git checkout --orphan "$branch_name"
    git add -A
    git commit \
        -m "nuke(git): Regular commit history cleanup" \
        -m "Initialize repository to clean all commit history using commit history cleaner script" \
        -s
}

delete_branch() {
    local branch_name=$1
    git branch -D "$branch_name" || true
}

rename_branch() {
    local new_name=$2
    git branch -m "$new_name"
}

push_branch() {
    local branch_name=$1
    git push -f origin "$branch_name"
    git branch --set-upstream-to=origin/"$branch_name"
}

reset_branch() {
    local new_branch="latest_branch"
    local base_branch="main"

    echo "This script will delete the '${base_branch}' branch and create the '${new_branch}' branch."
    confirm_action "Do you want to continue?"

    command_exists "git"
    change_to_git_root
    initialize_new_branch "$new_branch"
    delete_branch "$base_branch"
    rename_branch "$new_branch" "$base_branch"
    push_branch "$base_branch"

    echo "Done."
}

reset_branch
