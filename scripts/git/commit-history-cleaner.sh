#!/bin/bash

# Function to check if a command exists
command_exists() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' command is not installed."
        exit 1
    fi
}

# Function to prompt the user for confirmation
confirm_action() {
    local prompt_message=$1
    read -p "$prompt_message (yY/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation canceled by user."
        exit 1
    fi
}

# Function to initialize a new orphan branch
initialize_new_branch() {
    local branch_name=$1
    git checkout --orphan "$branch_name"
    git add -A
    git commit \
        -m "nuke(git): Regular commit history cleanup" \
        -m "Initialize repository to clean all commit history using commit history cleaner script" \
        -s
}

# Function to delete an existing branch
delete_branch() {
    local branch_name=$1
    git branch -D "$branch_name" || true
}

# Function to rename a branch
rename_branch() {
    local old_name=$1
    local new_name=$2
    git branch -m "$new_name"
}

# Function to push the branch to the remote repository
push_branch() {
    local branch_name=$1
    git push -f origin "$branch_name"
    git branch --set-upstream-to=origin/"$branch_name"
}

# Main function to delete and create branches
reset_branch() {
    local new_branch="latest_branch"
    local base_branch="main"

    echo "This script will delete the '${base_branch}' branch and create the '${new_branch}' branch."
    confirm_action "Do you want to continue?"

    command_exists "git"
    initialize_new_branch "$new_branch"
    delete_branch "$base_branch"
    rename_branch "$new_branch" "$base_branch"
    push_branch "$base_branch"

    echo "Done."
}

# Main script execution
reset_branch