#!/bin/bash

# postgres-query.sh - Run PostgreSQL queries (READ-ONLY)
# Works in both Codespace (queries local Supabase) and local Mac (queries cloud DB)
# Usage: ./postgres-query.sh <env> "SELECT * FROM table"
#        ./postgres-query.sh develop1 "SELECT * FROM table"
#
# Environment is REQUIRED. If not specified, reads from .env.active file.
# NOTE: DELETE/UPDATE/INSERT statements are blocked for safety.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
if [[ "$1" =~ ^(develop[0-9]*|staging|production)$ ]]; then
  TARGET_ENV="$1"
  QUERY="$2"
else
  # No env specified - read from .env.active
  TARGET_ENV=$(get_active_env)
  QUERY="$1"
fi

if [ -z "$TARGET_ENV" ]; then
  echo "Error: No environment specified and .env.active not found"
  echo "Usage: ./postgres-query.sh <env> \"SELECT * FROM table\""
  echo "       ./postgres-query.sh develop1 \"SELECT * FROM table\""
  echo "Or create .env.active with the environment name"
  exit 1
fi

# Special shortcut: CRL = find Crab Rangoon Long item and trace to menu versions
if [ "$QUERY" = "CRL" ] || [ "$QUERY" = "crl" ]; then
  QUERY="
-- Find Crab Rangoon Long item
WITH crl_item AS (
  SELECT id, name, base_price
  FROM menu_items
  WHERE LOWER(name) LIKE '%crab%'
    AND LOWER(name) LIKE '%rangoon%'
    AND LOWER(name) LIKE '%long%'
  LIMIT 1
),
-- Find categories containing this item
crl_categories AS (
  SELECT c.id as cat_id, c.name as cat_name
  FROM menu_categories c, crl_item i
  WHERE c.menu_item_ids::text LIKE '%' || i.id || '%'
),
-- Find menu versions containing these categories
crl_versions AS (
  SELECT DISTINCT v.id, v.version, v.pos_status
  FROM menu_versions v, crl_categories c
  WHERE v.menu_category_ids::text LIKE '%' || c.cat_id || '%'
  AND v.restaurant_id = 23
)
SELECT 'ITEM' as type, i.id::text, i.name, i.base_price::text as info FROM crl_item i
UNION ALL
SELECT 'CATEGORY', c.cat_id::text, c.cat_name, '' FROM crl_categories c
UNION ALL
SELECT 'VERSION', v.id::text, 'v' || v.version, v.pos_status::text FROM crl_versions v
ORDER BY type, info DESC;
"
fi

if [ -z "$QUERY" ]; then
  echo "Usage: ./postgres-query.sh <env> \"SELECT * FROM table\""
  echo "       ./postgres-query.sh develop1 \"SELECT * FROM table\""
  echo ""
  echo "Shortcuts:"
  echo "  CRL       Find 'Crab Rangoon Long' item and trace to menu versions"
  echo ""
  echo "Active environment: $TARGET_ENV"
  echo "NOTE: This tool is read-only. DELETE/UPDATE/INSERT are blocked."
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
