#!/bin/bash

# postgres-query.sh - Run PostgreSQL queries using credentials from .env.local
# Usage: ./postgres-query.sh "SELECT * FROM table"

set -e

# Find SparkPos repository by git remote URL suffix
find_sparkpos() {
    local search_depth=3
    local target_suffix="SparkPos.git"

    while IFS= read -r git_dir; do
        local repo_dir=$(dirname "$git_dir")
        local remote_url=$(git -C "$repo_dir" remote get-url origin 2>/dev/null || echo "")

        if [[ "$remote_url" == *"$target_suffix"* ]] && [[ -f "$repo_dir/.env.local" ]]; then
            echo "$repo_dir"
            return 0
        fi
    done < <(find "$HOME" -maxdepth $search_depth -type d -name ".git" 2>/dev/null)

    echo "Error: SparkPos repository with .env.local not found within $search_depth levels of home directory" >&2
    exit 1
}

SPARKPOS_DIR=$(find_sparkpos)

# Source env file
source "$SPARKPOS_DIR/.env.local"

# Run query using DATABASE_URL_DEVELOP
psql "$DATABASE_URL_DEVELOP" -c "$1" 2>&1
