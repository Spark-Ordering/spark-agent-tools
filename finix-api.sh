#!/bin/bash

# finix-api.sh - Query Finix API without exposing credentials
# Usage: ./finix-api.sh <env> <endpoint> [query_params]
#
# Examples:
#   ./finix-api.sh production /cost_profiles/cost_profile_cw43qFXmacDSddF21TPPw
#   ./finix-api.sh production /costs linked_id=TRuQcqGvU8i2qwbGfYmGC9N3
#   ./finix-api.sh production /fees linked_id=TRuQcqGvU8i2qwbGfYmGC9N3
#   ./finix-api.sh production /transfers/TRuQcqGvU8i2qwbGfYmGC9N3
#   ./finix-api.sh develop1 /fees linked_id=TR2Lgc585nm5dys6yXktRUoA
#
# Credentials are loaded from .env.<env> and never printed.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPARKPOS_DIR="$(cd "$SCRIPT_DIR/../SparkPos" && pwd)"

ENV="$1"
ENDPOINT="$2"
shift 2 2>/dev/null || true

if [ -z "$ENV" ] || [ -z "$ENDPOINT" ]; then
  echo "Usage: finix-api.sh <env> <endpoint> [query_params...]"
  echo ""
  echo "Examples:"
  echo "  finix-api.sh production /cost_profiles/cost_profile_cw43qFXmacDSddF21TPPw"
  echo "  finix-api.sh production /costs linked_id=TR..."
  echo "  finix-api.sh production /fees linked_id=TR..."
  echo "  finix-api.sh production /transfers/TR..."
  exit 1
fi

# Load env file
ENV_FILE="$SPARKPOS_DIR/.env.$ENV"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found"
  exit 1
fi

# Source credentials without displaying
set -a
source "$ENV_FILE"
set +a

if [ -z "$FINIX_USERNAME" ] || [ -z "$FINIX_PASSWORD" ] || [ -z "$FINIX_BASE_URL" ]; then
  echo "Error: FINIX_USERNAME, FINIX_PASSWORD, or FINIX_BASE_URL not set in $ENV_FILE"
  exit 1
fi

echo "# Querying Finix ($ENV): $ENDPOINT"

# Build query string from remaining args
QUERY_STRING=""
if [ $# -gt 0 ]; then
  QUERY_STRING="?$(IFS='&'; echo "$*")"
fi

# Make the request
curl -s \
  -u "$FINIX_USERNAME:$FINIX_PASSWORD" \
  -H "Content-Type: application/json" \
  -H "Finix-Version: 2022-02-01" \
  "$FINIX_BASE_URL$ENDPOINT$QUERY_STRING" | python3 -m json.tool
