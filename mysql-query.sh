#!/bin/bash

# mysql-query.sh - Run MySQL queries using credentials from .env.local
# Usage: ./mysql-query.sh "SELECT * FROM table"

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/repo-finder.sh"
source "$SCRIPT_DIR/query-safeguards.sh"

SPARK_BACKEND_DIR=$(find_repo "spark_backend.git")

# Source env file
source "$SPARK_BACKEND_DIR/.env.local"

# Parse credentials from AWS_DATABASE_URL
# Format: mysql2://username:password@host/database
DB_USER=$(echo $AWS_DATABASE_URL | sed -n 's|.*://\([^:]*\):.*|\1|p')
DB_PASS=$(echo $AWS_DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
DB_HOST=$(echo $AWS_DATABASE_URL | sed -n 's|.*@\([^/]*\)/.*|\1|p')
DB_NAME=$(echo $AWS_DATABASE_URL | sed -n 's|.*/\([^?]*\).*|\1|p')

# Validate query before execution
validate_query "$1" "mysql" "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME"

# Run query
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$1" 2>&1 | grep -v "Warning"
