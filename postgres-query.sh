#!/bin/bash

# postgres-query.sh - Run PostgreSQL queries
# Works in both Codespace (queries local Supabase) and local Mac (queries cloud DB)
# Usage: ./postgres-query.sh "SELECT * FROM table"
#        ./postgres-query.sh develop1 "SELECT * FROM table"  # Query specific environment

set -e

# Check if first arg is an environment name (develop1, develop2, etc.)
if [[ "$1" =~ ^develop[0-9]+$ ]]; then
  TARGET_ENV="$1"
  QUERY="$2"
else
  TARGET_ENV=""
  QUERY="$1"
fi

if [ -z "$QUERY" ]; then
  echo "Usage: ./postgres-query.sh \"SELECT * FROM table\""
  echo "       ./postgres-query.sh develop1 \"SELECT * FROM table\""
  exit 1
fi

# Detect environment
if [ -d /workspaces ]; then
  # Running in Codespace - query local Supabase postgres container
  docker exec supabase_db_sparkpos psql -U postgres -c "$QUERY" 2>&1
else
  # Running on local Mac - query cloud database
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/repo-finder.sh"
  source "$SCRIPT_DIR/query-safeguards.sh"

  SPARKPOS_DIR=$(find_repo "SparkPos.git")

  # Load base .env.local first
  source "$SPARKPOS_DIR/.env.local"

  # If target environment specified, overlay with its values
  if [ -n "$TARGET_ENV" ]; then
    ENV_FILE="$SPARKPOS_DIR/.env.${TARGET_ENV}"
    if [ -f "$ENV_FILE" ]; then
      source "$ENV_FILE"
      # Use DIRECT_URL from the env file (direct connection, not pgbouncer)
      DB_URL="$DIRECT_URL"
    else
      echo "Error: Environment file $ENV_FILE not found"
      exit 1
    fi
  else
    DB_URL="$DATABASE_URL_DEVELOP"
  fi

  validate_query "$QUERY" "postgres" "$DB_URL"
  psql "$DB_URL" -c "$QUERY" 2>&1
fi
