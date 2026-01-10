#!/bin/bash

# postgres-query.sh - Run PostgreSQL queries using credentials from .env.local
# Usage: ./postgres-query.sh "SELECT * FROM table"

set -e

# Load repo finder utility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/repo-finder.sh"

SPARKPOS_DIR=$(find_repo "SparkPos.git")

# Source env file
source "$SPARKPOS_DIR/.env.local"

# Run query using DATABASE_URL_DEVELOP
psql "$DATABASE_URL_DEVELOP" -c "$1" 2>&1
