#!/bin/bash

# postgres-query.sh - Run PostgreSQL queries
# Works in both Codespace (queries local Supabase) and local Mac (queries cloud DB)
# Usage: ./postgres-query.sh <env> "SELECT * FROM table"
#        ./postgres-query.sh develop1 "SELECT * FROM table"
#        ./postgres-query.sh --delete develop1 "DELETE FROM table WHERE id = 'x'"
#
# Options:
#   --delete  Allow DELETE statements (requires WHERE clause)
#
# Environment is REQUIRED. If not specified, reads from .env.active file.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse --delete flag
ALLOW_DELETE=0
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--delete" ]; then
    ALLOW_DELETE=1
  else
    ARGS+=("$arg")
  fi
done
export ALLOW_DELETE

# Function to get active environment from .env.active
get_active_env() {
  source "$SCRIPT_DIR/repo-finder.sh"
  local SPARKPOS_DIR=$(find_repo "SparkPos.git")
  local ACTIVE_FILE="$SPARKPOS_DIR/.env.active"
  if [ -f "$ACTIVE_FILE" ]; then
    cat "$ACTIVE_FILE" | tr -d '[:space:]'
  else
    echo ""
  fi
}

# Check if first arg is an environment name (develop, develop1, develop2, staging, production, etc.)
if [[ "${ARGS[0]}" =~ ^(develop[0-9]*|staging|production)$ ]]; then
  TARGET_ENV="${ARGS[0]}"
  QUERY="${ARGS[1]}"
else
  # No env specified - read from .env.active
  TARGET_ENV=$(get_active_env)
  QUERY="${ARGS[0]}"
fi

if [ -z "$TARGET_ENV" ]; then
  echo "Error: No environment specified and .env.active not found"
  echo "Usage: ./postgres-query.sh <env> \"SELECT * FROM table\""
  echo "       ./postgres-query.sh develop1 \"SELECT * FROM table\""
  echo "       ./postgres-query.sh --delete develop1 \"DELETE FROM table WHERE id = 'x'\""
  echo "Or create .env.active with the environment name"
  exit 1
fi

if [ -z "$QUERY" ]; then
  echo "Usage: ./postgres-query.sh <env> \"SELECT * FROM table\""
  echo "       ./postgres-query.sh develop1 \"SELECT * FROM table\""
  echo "       ./postgres-query.sh --delete develop1 \"DELETE FROM table WHERE id = 'x'\""
  echo ""
  echo "Options:"
  echo "  --delete  Allow DELETE statements (requires WHERE clause)"
  echo ""
  echo "Active environment: $TARGET_ENV"
  exit 1
fi

# Detect environment
if [ -d /workspaces ]; then
  # Running in Codespace - query local Supabase postgres container
  docker exec supabase_db_sparkpos psql -U postgres -c "$QUERY" 2>&1
else
  # Running on local Mac - query cloud database
  source "$SCRIPT_DIR/repo-finder.sh"
  source "$SCRIPT_DIR/query-safeguards.sh"

  SPARKPOS_DIR=$(find_repo "SparkPos.git")

  # Load base .env.local first
  source "$SPARKPOS_DIR/.env.local"

  # Load environment-specific file
  if [ "$TARGET_ENV" = "develop" ]; then
    # For 'develop', use DATABASE_URL_DEVELOP from .env.local
    DB_URL="$DATABASE_URL_DEVELOP"
  else
    ENV_FILE="$SPARKPOS_DIR/.env.${TARGET_ENV}"
    if [ -f "$ENV_FILE" ]; then
      source "$ENV_FILE"
      # Use DIRECT_URL from the env file (direct connection, not pgbouncer)
      DB_URL="$DIRECT_URL"
    else
      echo "Error: Environment file $ENV_FILE not found"
      exit 1
    fi
  fi

  echo "# Querying: $TARGET_ENV"
  validate_query "$QUERY" "postgres" "$DB_URL"
  psql "$DB_URL" -c "$QUERY" 2>&1
fi
