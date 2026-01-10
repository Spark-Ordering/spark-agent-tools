#!/bin/bash

# mysql-query.sh - Run MySQL queries using credentials from .env.local
# Usage: ./mysql-query.sh "SELECT * FROM table"

set -e

# Find spark_backend repository by git remote URL suffix
find_spark_backend() {
    local search_depth=3
    local target_suffix="spark_backend.git"

    while IFS= read -r git_dir; do
        local repo_dir=$(dirname "$git_dir")
        local remote_url=$(git -C "$repo_dir" remote get-url origin 2>/dev/null || echo "")

        if [[ "$remote_url" == *"$target_suffix"* ]] && [[ -f "$repo_dir/.env.local" ]]; then
            echo "$repo_dir"
            return 0
        fi
    done < <(find "$HOME" -maxdepth $search_depth -type d -name ".git" 2>/dev/null)

    echo "Error: spark_backend repository with .env.local not found within $search_depth levels of home directory" >&2
    exit 1
}

SPARK_BACKEND_DIR=$(find_spark_backend)

# Source env file
source "$SPARK_BACKEND_DIR/.env.local"

# Parse credentials from AWS_DATABASE_URL
# Format: mysql2://username:password@host/database
DB_USER=$(echo $AWS_DATABASE_URL | sed -n 's|.*://\([^:]*\):.*|\1|p')
DB_PASS=$(echo $AWS_DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
DB_HOST=$(echo $AWS_DATABASE_URL | sed -n 's|.*@\([^/]*\)/.*|\1|p')
DB_NAME=$(echo $AWS_DATABASE_URL | sed -n 's|.*/\([^?]*\).*|\1|p')

# Run query
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$1" 2>&1 | grep -v "Warning"
