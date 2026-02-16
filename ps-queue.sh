#!/bin/bash
# PowerSync upload queue management
# Usage: ps-queue.sh [check|clear|show]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-check}" in
  check)
    COUNT=$("$SCRIPT_DIR/sqlite-query.sh" --fresh "SELECT COUNT(*) FROM ps_crud" 2>/dev/null)
    if [ "$COUNT" -gt 0 ]; then
      echo "⚠️  PowerSync queue blocked: $COUNT items stuck"
      "$SCRIPT_DIR/sqlite-query.sh" --fresh "SELECT DISTINCT json_extract(data, '\$.type') as table_name, COUNT(*) as count FROM ps_crud GROUP BY table_name" 2>/dev/null
    else
      echo "✓ PowerSync queue clear"
    fi
    ;;
  clear)
    "$SCRIPT_DIR/sqlite-query.sh" --write "DELETE FROM ps_crud" 2>/dev/null
    echo "✓ PowerSync queue cleared"
    ;;
  show)
    "$SCRIPT_DIR/sqlite-query.sh" --fresh "SELECT id, tx_id, json_extract(data, '\$.op') as op, json_extract(data, '\$.type') as type, json_extract(data, '\$.id') as row_id FROM ps_crud ORDER BY id LIMIT 20" 2>/dev/null
    ;;
  *)
    echo "Usage: ps-queue.sh [check|clear|show]"
    echo "  check - Show queue status (default)"
    echo "  clear - Clear all stuck items"
    echo "  show  - Show first 20 items in queue"
    ;;
esac
