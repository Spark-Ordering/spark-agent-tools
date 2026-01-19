#!/bin/bash

# postgres-query.sh - Run PostgreSQL queries
# Works in both Codespace (queries local Supabase) and local Mac (queries cloud DB)
# Usage: ./postgres-query.sh "SELECT * FROM table"

set -e

QUERY="$1"

if [ -z "$QUERY" ]; then
  echo "Usage: ./postgres-query.sh \"SELECT * FROM table\""
  exit 1
fi

# Detect environment
if [ -d /workspaces ]; then
  # Running in Codespace - query local Supabase postgres container
  docker exec supabase_db_sparkpos psql -U postgres -c "$QUERY" 2>&1
else
  # Running on local Mac - query cloud database via DATABASE_URL_DEVELOP
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/repo-finder.sh"
  source "$SCRIPT_DIR/query-safeguards.sh"

  SPARKPOS_DIR=$(find_repo "SparkPos.git")
  source "$SPARKPOS_DIR/.env.local"

  validate_query "$QUERY" "postgres" "$DATABASE_URL_DEVELOP"
  psql "$DATABASE_URL_DEVELOP" -c "$QUERY" 2>&1
fi
