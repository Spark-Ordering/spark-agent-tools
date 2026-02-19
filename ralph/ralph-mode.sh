#!/bin/bash
# ralph-mode.sh - Toggle autonomous mode for Claude Code
#
# Usage:
#   ralph              # Enable (uses most recent plan)
#   ralph PLAN.md      # Enable with specific plan
#   ralph off          # Disable
#   ralph status       # Check status

RALPH_FLAG="$HOME/.claude/.ralph-mode"

# No args = enable with auto-detect
if [[ $# -eq 0 ]]; then
    touch "$RALPH_FLAG"
    latest=$(ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1)
    echo "🔄 Ralph mode ON"
    if [[ -n "$latest" ]]; then
        echo "   Latest plan: $latest"
        unchecked=$(grep -c '^\s*- \[ \]' "$latest" 2>/dev/null || echo "0")
        echo "   Tasks remaining: $unchecked"
    fi
    exit 0
fi

case "$1" in
    off|disable|stop)
        rm -f "$RALPH_FLAG"
        echo "⏹️  Ralph mode OFF"
        ;;
    status)
        if [[ -f "$RALPH_FLAG" ]]; then
            echo "🔄 Ralph mode: ON"
            latest=$(ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1)
            if [[ -n "$latest" ]]; then
                echo "   Latest plan: $latest"
                unchecked=$(grep -c '^\s*- \[ \]' "$latest" 2>/dev/null || echo "0")
                echo "   Tasks remaining: $unchecked"
            fi
        else
            echo "⏹️  Ralph mode: OFF"
        fi
        ;;
    *.md)
        # Specific plan file
        echo "$1" > "$RALPH_FLAG"
        echo "🔄 Ralph mode ON"
        echo "   Plan: $1"
        unchecked=$(grep -c '^\s*- \[ \]' "$1" 2>/dev/null || echo "0")
        echo "   Tasks remaining: $unchecked"
        ;;
    *)
        echo "Usage: ralph [off|status|PLAN.md]"
        exit 1
        ;;
esac
