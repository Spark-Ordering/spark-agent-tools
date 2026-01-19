#!/bin/bash

# repo-finder.sh - Utility to find Spark repositories by git remote URL suffix
# Usage: source repo-finder.sh; find_repo "spark_backend.git"

find_repo() {
    local target_suffix="$1"
    local search_depth=3

    if [[ -z "$target_suffix" ]]; then
        echo "Error: target_suffix required" >&2
        return 1
    fi

    # Determine search directories based on environment
    # On Codespace, repos are under /workspaces, not $HOME
    local search_dirs=("$HOME")
    if [[ -d /workspaces ]]; then
        search_dirs+=("/workspaces")
    fi

    for search_dir in "${search_dirs[@]}"; do
        while IFS= read -r git_dir; do
            local repo_dir=$(dirname "$git_dir")
            local remote_url=$(git -C "$repo_dir" remote get-url origin 2>/dev/null || echo "")

            if [[ "$remote_url" == *"$target_suffix"* ]] && [[ -f "$repo_dir/.env.local" ]]; then
                echo "$repo_dir"
                return 0
            fi
        done < <(find "$search_dir" -maxdepth $search_depth -type d -name ".git" 2>/dev/null)
    done

    echo "Error: Repository with suffix '$target_suffix' and .env.local not found" >&2
    return 1
}
