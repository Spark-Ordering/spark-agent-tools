#!/bin/bash

# seed-test-restaurant.sh - Seeds Athens Wok Local data into local MySQL
# This enables placing test orders against the same restaurant data used in staging
#
# Usage: ./seed-test-restaurant.sh
# Must be run from within Codespace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_FILE="$SCRIPT_DIR/seeds/athens-wok-local.sql"

# Detect environment
if [ -d /workspaces ]; then
  # Running in Codespace - use docker exec
  # Find the MySQL container (could be 'mysql' or 'mysql_sparkpos')
  MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E '^mysql' | head -1)
  if [ -z "$MYSQL_CONTAINER" ]; then
    echo "Error: No MySQL container found"
    exit 1
  fi
  MYSQL_CMD="docker exec -i $MYSQL_CONTAINER mysql -uroot -proot SPARK"
else
  echo "This script should be run from within a Codespace."
  echo "Run: gh codespace ssh -c <name> -- 'cd /workspaces/spark-agent-tools && ./seed-test-restaurant.sh'"
  exit 1
fi

if [ ! -f "$SEED_FILE" ]; then
  echo "Error: Seed file not found: $SEED_FILE"
  exit 1
fi

echo "Seeding Athens Wok Local (franchise_id=25, restaurant_id=23)..."

$MYSQL_CMD < "$SEED_FILE" 2>/dev/null

echo "✓ Done! Available at: http://localhost:3000/awlocal"
