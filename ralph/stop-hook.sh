#!/bin/bash
# ralph-stop-hook.sh - Prevents Claude from stopping if tasks remain in active plan
#
# Checks for unchecked tasks (- [ ]) in the current plan file.
# If found, returns error to block the stop.
#
# To enable autonomous mode: touch ~/.claude/.ralph-mode
# To disable: rm ~/.claude/.ralph-mode

RALPH_FLAG="$HOME/.claude/.ralph-mode"
PLAN_FILE=""

# Only run if ralph mode is enabled
if [[ ! -f "$RALPH_FLAG" ]]; then
    exit 0
fi

# Read plan file path from the flag file (if specified)
if [[ -s "$RALPH_FLAG" ]]; then
    PLAN_FILE=$(cat "$RALPH_FLAG")
fi

# Default to most recently modified plan file
if [[ -z "$PLAN_FILE" ]] || [[ ! -f "$PLAN_FILE" ]]; then
    PLAN_FILE=$(ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1)
fi

if [[ -z "$PLAN_FILE" ]] || [[ ! -f "$PLAN_FILE" ]]; then
    # No plan file found, allow stop
    exit 0
fi

# Count unchecked tasks
unchecked=$(grep -c '^\s*- \[ \]' "$PLAN_FILE" 2>/dev/null || echo "0")

if [[ "$unchecked" -gt 0 ]]; then
    echo "🔄 Ralph mode: $unchecked tasks remaining in $(basename "$PLAN_FILE")" >&2
    echo "Complete the tasks to stop." >&2
    exit 2  # Exit 2 = BLOCK the stop (Claude continues working)
fi

# All tasks complete
echo "✅ All tasks complete! Disabling ralph mode."
rm -f "$RALPH_FLAG"
exit 0
