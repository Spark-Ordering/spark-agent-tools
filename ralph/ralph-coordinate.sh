#!/bin/bash
# ralph-coordinate.sh - Manage coordination messages between team members
#
# Usage:
#   ralph-coordinate.sh check                    # Check for pending messages
#   ralph-coordinate.sh send <agent> "message"   # Leave message for other agent
#   ralph-coordinate.sh clear                    # Clear all messages
#   ralph-coordinate.sh conflict <agent> <files> # Start conflict resolution
#
# Coordination file lives in the plan directory so both agents can see it.

COORD_DIR="$HOME/.claude/coordination"
mkdir -p "$COORD_DIR"

action="${1:-check}"

case "$action" in
    check)
        # Show any pending coordination messages
        if [[ -f "$COORD_DIR/messages.txt" ]]; then
            count=$(wc -l < "$COORD_DIR/messages.txt" | tr -d ' ')
            if [[ "$count" -gt 0 ]]; then
                echo "📬 $count pending coordination message(s):"
                echo ""
                cat "$COORD_DIR/messages.txt"
                echo ""
                echo "Clear with: ralph-coordinate.sh clear"
            else
                echo "📭 No pending messages"
            fi
        else
            echo "📭 No pending messages"
        fi

        # Check for active conflict
        if [[ -f "$COORD_DIR/conflict.json" ]]; then
            echo ""
            echo "⚠️  ACTIVE CONFLICT:"
            cat "$COORD_DIR/conflict.json"
        fi
        ;;

    send)
        to_agent="${2:-}"
        message="${3:-}"
        from_agent="${RALPH_AGENT:-unknown}"

        if [[ -z "$message" ]]; then
            echo "Usage: ralph-coordinate.sh send <agent> \"message\"" >&2
            exit 1
        fi

        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $from_agent → $to_agent: $message" >> "$COORD_DIR/messages.txt"
        echo "📤 Message sent to $to_agent"
        ;;

    clear)
        rm -f "$COORD_DIR/messages.txt"
        echo "🗑️  Messages cleared"
        ;;

    conflict)
        agent="${2:-}"
        shift 2
        files="$*"

        if [[ -z "$agent" ]] || [[ -z "$files" ]]; then
            echo "Usage: ralph-coordinate.sh conflict <agent> <files...>" >&2
            exit 1
        fi

        # Create conflict record
        cat > "$COORD_DIR/conflict.json" << EOF
{
  "initiated_by": "$agent",
  "timestamp": "$(date -Iseconds)",
  "files": "$files",
  "status": "pending",
  "resolution": null
}
EOF
        echo "🚨 Conflict coordination initiated"
        echo "   Files: $files"
        echo ""
        echo "Use SendMessage to discuss with teammate, then update:"
        echo "  ralph-coordinate.sh resolve \"keep-mine|keep-theirs|merged\""
        ;;

    resolve)
        resolution="${2:-merged}"
        if [[ -f "$COORD_DIR/conflict.json" ]]; then
            # Update status (simple sed approach)
            sed -i '' 's/"status": "pending"/"status": "resolved"/' "$COORD_DIR/conflict.json"
            sed -i '' "s/\"resolution\": null/\"resolution\": \"$resolution\"/" "$COORD_DIR/conflict.json"
            echo "✅ Conflict marked as resolved: $resolution"
        else
            echo "No active conflict to resolve"
        fi
        ;;

    *)
        echo "Usage: ralph-coordinate.sh [check|send|clear|conflict|resolve]"
        exit 1
        ;;
esac
