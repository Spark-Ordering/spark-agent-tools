#!/bin/bash

# mysql-query.sh - Run MySQL queries
# Usage: ./mysql-query.sh "SELECT * FROM table"
#
# Environment handling:
# - On Mac: Queries staging MySQL via AWS_DATABASE_URL from spark_backend/.env.local
# - On Codespace: Queries local MySQL Docker container (database: SPARK)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect environment and set up MySQL command
if [[ -d /workspaces ]]; then
    # Running in Codespace - use Docker container
    MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^mysql' | head -1)
    if [[ -z "$MYSQL_CONTAINER" ]]; then
        echo "Error: No MySQL container found. Is MySQL running?" >&2
        exit 1
    fi

    # Codespace MySQL uses root/root and database SPARK
    run_query() {
        docker exec -i "$MYSQL_CONTAINER" mysql -uroot -proot SPARK -e "$1" 2>&1 | grep -v "Warning" || true
    }

    DB_HOST="localhost (Docker: $MYSQL_CONTAINER)"
    DB_NAME="SPARK"
else
    # Running locally - use AWS credentials from spark_backend
    source "$SCRIPT_DIR/repo-finder.sh"
    source "$SCRIPT_DIR/query-safeguards.sh"

    SPARK_BACKEND_DIR=$(find_repo "spark_backend.git")

    # Extract AWS_DATABASE_URL from env file (don't source entire file - may have syntax issues)
    AWS_DATABASE_URL=$(grep -E '^AWS_DATABASE_URL=' "$SPARK_BACKEND_DIR/.env.local" | head -1 | cut -d'=' -f2-)

    if [[ -z "$AWS_DATABASE_URL" ]]; then
        echo "Error: AWS_DATABASE_URL not found in $SPARK_BACKEND_DIR/.env.local" >&2
        exit 1
    fi

    # Parse credentials from AWS_DATABASE_URL
    # Format: mysql2://username:password@host/database
    DB_USER=$(echo $AWS_DATABASE_URL | sed -n 's|.*://\([^:]*\):.*|\1|p')
    DB_PASS=$(echo $AWS_DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
    DB_HOST=$(echo $AWS_DATABASE_URL | sed -n 's|.*@\([^/]*\)/.*|\1|p')
    DB_NAME=$(echo $AWS_DATABASE_URL | sed -n 's|.*/\([^?]*\).*|\1|p')

    # Validate query before execution (only for remote databases)
    validate_query "$1" "mysql" "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME"

    run_query() {
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$1" 2>&1 | grep -v "Warning" || true
    }
fi

# Run the query
run_query "$1"
