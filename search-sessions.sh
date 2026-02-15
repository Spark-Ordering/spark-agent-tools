#!/usr/bin/env bash
# Search all past session JSONL files for a keyword/phrase.
# Usage: search-sessions.sh <query> [max_results]
# Example: search-sessions.sh "Tuzzi" 10
#
# Searches user and assistant messages across ALL sessions.
# Returns matching lines with session ID and role context.

set -euo pipefail

QUERY="${1:?Usage: search-sessions.sh <query> [max_results]}"
MAX_RESULTS="${2:-20}"
SESSIONS_DIR="$HOME/.clawdbot/agents/main/sessions"

if [ ! -d "$SESSIONS_DIR" ]; then
  echo "No sessions directory found at $SESSIONS_DIR"
  exit 1
fi

COUNT=0
for f in "$SESSIONS_DIR"/*.jsonl; do
  [ -f "$f" ] || continue
  SESSION_ID=$(basename "$f" .jsonl)
  
  MATCHES=$(jq -r --arg q "$QUERY" '
    select(.type=="message") |
    select(.message.role=="user" or .message.role=="assistant") |
    .message.content[]? |
    select(.type=="text") |
    select(.text | test($q; "i")) |
    .text[0:300]
  ' "$f" 2>/dev/null || true)
  
  if [ -n "$MATCHES" ]; then
    echo "=== Session: $SESSION_ID ==="
    # Get timestamp of first message for context
    FIRST_TS=$(jq -r 'select(.timestamp != null) | .timestamp' "$f" 2>/dev/null | head -1)
    echo "Started: $FIRST_TS"
    echo "$MATCHES" | head -5
    echo "---"
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge "$MAX_RESULTS" ]; then
      echo "(Stopped at $MAX_RESULTS results)"
      break
    fi
  fi
done

if [ "$COUNT" -eq 0 ]; then
  echo "No sessions found matching '$QUERY'"
fi
