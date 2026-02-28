#!/bin/bash
# ralph-stop-hook.sh - Autonomous task + merge workflow
#
# Uses Python merge.py for clean turn-based merge logic.

RALPH_FLAG="$HOME/.claude/.ralph-mode"
MERGE_PY="$HOME/Code/spark-agent-tools/ralph/merge.py"
RALPH_AGENT_SCRIPT="$HOME/Code/spark-agent-tools/ralph/ralph-agent.sh"
REMOTE_CHECK="$HOME/Code/spark-agent-tools/ralph/ralph-remote-check.sh"

# Only run if ralph mode is enabled
[[ ! -f "$RALPH_FLAG" ]] && exit 0

# Get agent
if [[ -f "$RALPH_AGENT_SCRIPT" ]]; then
    source "$RALPH_AGENT_SCRIPT"
fi

get_plan_file() {
    if [[ -s "$RALPH_FLAG" ]]; then
        local from_flag=$(cat "$RALPH_FLAG")
        [[ "$from_flag" == *":"* ]] && from_flag="${from_flag#*:}"
        [[ -f "$from_flag" ]] && echo "$from_flag" && return
    fi
    ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1
}

count_unchecked() {
    local agent="$1"
    local plan_file="$2"
    "$HOME/Code/spark-agent-tools/ralph/ralph-count.sh" "$agent" "$plan_file" 2>/dev/null | tail -1
}

AGENT="${RALPH_AGENT:-all}"
PLAN_FILE=$(get_plan_file)

[[ -z "$PLAN_FILE" || ! -f "$PLAN_FILE" ]] && exit 0

# === TASK PHASE ===
unchecked=$(count_unchecked "$AGENT" "$PLAN_FILE")

if [[ "$unchecked" -gt 0 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🔄 $AGENT: $unchecked tasks remaining" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "" >&2
    echo "💡 Tips:" >&2
    echo "   • If you saw an error: add it to top of plan and fix it before other tasks" >&2
    echo "   • Look at established patterns in the codebase for guidance" >&2
    echo "   • If you appear stuck, use WebSearch to research the problem" >&2
    echo "" >&2
    echo "NEXT ACTION: Continue working on your $AGENT tasks in $PLAN_FILE" >&2
    exit 2
fi

# === ALL MY TASKS DONE ===
if [[ "$AGENT" == "all" ]]; then
    echo "✅ All tasks complete!" >&2
    rm -f "$RALPH_FLAG"
    exit 0
fi

# Check other agent
other=$([[ "$AGENT" == "dev1" ]] && echo "dev2" || echo "dev1")

# Check if other machine is online
source "$REMOTE_CHECK"

if ! is_remote_online; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "✅ YOUR TASKS COMPLETE - $other is offline, stopping." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    rm -f "$RALPH_FLAG"
    exit 0
fi

other_unchecked=$(count_unchecked "$other" "$PLAN_FILE")

if [[ "$other_unchecked" -gt 0 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "✅ YOUR TASKS COMPLETE - Waiting for $other ($other_unchecked tasks)" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Polling every 10s..." >&2

    for i in {1..60}; do
        sleep 10
        other_unchecked=$(count_unchecked "$other" "$PLAN_FILE")
        if [[ "$other_unchecked" -eq 0 ]]; then
            echo "🎉 $other finished!" >&2
            break
        fi
        echo "   $other: $other_unchecked tasks remaining..." >&2
    done

    [[ "$other_unchecked" -gt 0 ]] && echo "⚠️ Timeout." >&2 && exit 2
fi

# === MERGE PHASE - Use Python ===

# Merge requires dev2 for turn coordination - bail if unreachable
if ! is_remote_online; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "✅ YOUR TASKS COMPLETE - $other is offline, skipping merge." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    rm -f "$RALPH_FLAG"
    exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "🎉 ALL TASKS COMPLETE - MERGE PHASE" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "" >&2

# Get next action from Python - capture stderr separately for debugging
merge_stderr=$(mktemp)
next_json=$(python3 "$MERGE_PY" next-action 2>"$merge_stderr")
merge_exit=$?

if [[ -z "$next_json" ]] || [[ $merge_exit -ne 0 ]]; then
    # If merge.py failed because dev2 went offline mid-operation, exit cleanly
    if ! is_remote_online; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "⚠️  merge.py failed - $other went offline. Stopping." >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        rm -f "$merge_stderr"
        rm -f "$RALPH_FLAG"
        exit 0
    fi
    echo "ERROR: merge.py next-action failed (exit code: $merge_exit)" >&2
    if [[ -s "$merge_stderr" ]]; then
        echo "--- stderr ---" >&2
        cat "$merge_stderr" >&2
        echo "--- end stderr ---" >&2
    fi
    rm -f "$merge_stderr"
    exit 2
fi
rm -f "$merge_stderr"

# Parse JSON - actions is now a LIST
actions_json=$(echo "$next_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('actions') or []))")
wait_for=$(echo "$next_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('wait_for') or '')")
message=$(echo "$next_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message') or '')")
current_file=$(echo "$next_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('current_file') or '')")
phase=$(echo "$next_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('phase') or '')")
num_actions=$(echo "$actions_json" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")

# Show phase-appropriate context
if [[ "$phase" == "applying" ]] && [[ -n "$current_file" ]]; then
    echo "🔧 RESOLUTION PHASE - Applying agreed proposals" >&2
    echo "🔒 Current file: $current_file" >&2
    echo "" >&2
    # Show resolution info (proposal + file content)
    python3 "$MERGE_PY" show-resolution 2>&1 | head -80 >&2
    echo "" >&2
elif [[ "$phase" == "review" ]] && [[ -n "$current_file" ]]; then
    echo "💬 DISCUSSION PHASE" >&2
    echo "🔒 Current file: $current_file" >&2
    echo "" >&2
    # Show brief diff
    python3 "$MERGE_PY" show 2>&1 | head -60 >&2
    echo "" >&2
fi

# Handle waiting - use the built-in wait command
if [[ -n "$wait_for" ]]; then
    echo "⏳ $message" >&2
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "IMPORTANT: Use 'ralph merge wait' to poll for your turn." >&2
    echo "Do NOT write your own while loops - they cause sync issues." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "NEXT ACTION: ralph merge wait" >&2
    exit 2
fi

# Have action(s) to take - show ALL options
if [[ "$num_actions" -gt 0 ]]; then
    echo "$message" >&2
    echo "" >&2

    if [[ "$num_actions" -eq 1 ]]; then
        # Single action
        single_action=$(echo "$actions_json" | python3 -c "import sys,json; print(json.load(sys.stdin)[0])")
        echo "NEXT ACTION: $single_action" >&2
    else
        # Multiple actions - show ALL options
        echo "YOUR OPTIONS:" >&2
        echo "$actions_json" | python3 -c "
import sys, json
actions = json.load(sys.stdin)
for i, action in enumerate(actions, 1):
    print(f'  {i}. {action}', file=sys.stderr)
"
    fi
    exit 2
fi

# Should not reach here - next-action should always return something
echo "ERROR: No action returned. Run: ralph merge start" >&2
exit 2
