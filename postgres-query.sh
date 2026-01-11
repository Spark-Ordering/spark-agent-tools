#!/bin/bash

# postgres-query.sh - Run PostgreSQL queries using credentials from .env.local
# Usage: ./postgres-query.sh "SELECT * FROM table"

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/repo-finder.sh"
source "$SCRIPT_DIR/query-safeguards.sh"

SPARKPOS_DIR=$(find_repo "SparkPos.git")

# Source env file
source "$SPARKPOS_DIR/.env.local"

# Validate query before execution
validate_query "$1" "postgres" "$DATABASE_URL_DEVELOP"

# Run query using DATABASE_URL_DEVELOP
psql "$DATABASE_URL_DEVELOP" -c "$1" 2>&1
