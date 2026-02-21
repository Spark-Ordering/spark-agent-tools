#!/bin/bash
# ralph-rebalance.sh - Redistribute tasks when one agent finishes early
#
# Usage:
#   ralph-rebalance.sh              # Auto-detect and rebalance
#   ralph-rebalance.sh dev1         # Give unchecked tasks from dev2 to dev1
#   ralph-rebalance.sh --check      # Just show current distribution, don't change
#   ralph-rebalance.sh --cleanup    # Remove duplicate/orphan agent markers
#
# When one agent finishes their tasks, this reassigns remaining tasks
# from the other agent to balance the load.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get plan file
get_plan_file() {
    local flag="$HOME/.claude/.ralph-mode"
    if [[ -f "$flag" ]] && [[ -s "$flag" ]]; then
        local content=$(cat "$flag")
        if [[ "$content" == *":"* ]]; then
            local path="${content#*:}"
            if [[ -f "$path" ]]; then
                echo "$path"
                return
            fi
        fi
    fi
    ls -t "$HOME/.claude/plans/"*.md 2>/dev/null | head -1
}

# Count unchecked tasks for an agent
count_unchecked() {
    local agent="$1"
    local plan_file="$2"
    "$SCRIPT_DIR/ralph-count.sh" "$agent" "$plan_file" 2>/dev/null | tail -1
}

# Show current distribution
show_distribution() {
    local plan_file="$1"
    local dev1_tasks=$(count_unchecked "dev1" "$plan_file")
    local dev2_tasks=$(count_unchecked "dev2" "$plan_file")

    echo "Current task distribution:"
    echo "  dev1: $dev1_tasks unchecked"
    echo "  dev2: $dev2_tasks unchecked"
    echo "  Total: $((dev1_tasks + dev2_tasks)) unchecked"
}

# Cleanup duplicate/orphan agent markers
cleanup_markers() {
    local plan_file="$1"

    # Create backup
    cp "$plan_file" "${plan_file}.bak"

    # Remove lines that are ONLY "devN" or "<!-- agent: devN -->" with nothing else
    # Also consolidate consecutive markers
    awk '
    BEGIN { last_was_marker = 0; pending_marker = "" }

    # Skip bare "dev1" or "dev2" lines (artifacts from bad rebalance)
    /^dev[12]$/ { next }

    # Handle agent markers
    /^<!-- agent: dev[12] -->$/ {
        if (last_was_marker) {
            # Skip duplicate consecutive markers, keep the new one
            pending_marker = $0
        } else {
            pending_marker = $0
            last_was_marker = 1
        }
        next
    }

    # Non-marker line
    {
        # Print pending marker if we have one
        if (pending_marker != "") {
            print pending_marker
            pending_marker = ""
        }
        last_was_marker = 0
        print
    }

    END {
        # Print final pending marker if any
        if (pending_marker != "") {
            print pending_marker
        }
    }
    ' "$plan_file" > "${plan_file}.tmp"

    mv "${plan_file}.tmp" "$plan_file"
    echo "Cleaned up duplicate markers"
}

# Reassign tasks from one agent to another
rebalance_tasks() {
    local from_agent="$1"
    local to_agent="$2"
    local plan_file="$3"

    # First cleanup any existing mess
    cleanup_markers "$plan_file"

    local from_tasks=$(count_unchecked "$from_agent" "$plan_file")
    local to_tasks=$(count_unchecked "$to_agent" "$plan_file")

    if [[ "$from_tasks" -eq 0 ]]; then
        echo "No tasks to redistribute from $from_agent"
        return 0
    fi

    # Calculate how many to move (aim for equal split)
    local total=$((from_tasks + to_tasks))
    local target=$((total / 2))
    local to_move=$((from_tasks - target))

    if [[ "$to_move" -le 0 ]]; then
        echo "Tasks already balanced (or $to_agent has more)"
        return 0
    fi

    echo "Redistributing $to_move tasks from $from_agent to $to_agent..."

    # Create backup
    cp "$plan_file" "${plan_file}.bak"

    # Use awk to reassign tasks
    # Adds marker before first moved task and restores original agent after last moved task
    awk -v from="$from_agent" -v to="$to_agent" -v limit="$to_move" '
    BEGIN {
        current_agent = "all"  # Tasks before any marker
        moved = 0
        added_to_marker = 0
        need_restore_marker = 0
    }

    # Track current agent section
    /^<!-- agent: dev[12] -->/ {
        match($0, /dev[12]/)
        current_agent = substr($0, RSTART, RLENGTH)
        added_to_marker = 0
        need_restore_marker = 0
        print
        next
    }

    # Unchecked task - check if we should reassign
    /^[[:space:]]*- \[ \]/ {
        is_from_agent = (current_agent == from || current_agent == "all")

        if (is_from_agent && moved < limit) {
            # Need to reassign this task
            if (added_to_marker == 0) {
                print "<!-- agent: " to " -->"
                added_to_marker = 1
            }
            print
            moved++
            need_restore_marker = 1
            next
        }

        # Not moving this task - if we just finished moving, restore original agent
        if (need_restore_marker) {
            print "<!-- agent: " from " -->"
            need_restore_marker = 0
            added_to_marker = 0
        }
        print
        next
    }

    # Any other line - check if we need to restore marker before non-task content
    {
        if (need_restore_marker) {
            print "<!-- agent: " from " -->"
            need_restore_marker = 0
            added_to_marker = 0
        }
        print
    }
    ' "$plan_file" > "${plan_file}.tmp"

    mv "${plan_file}.tmp" "$plan_file"

    # Final cleanup
    cleanup_markers "$plan_file"

    # Show new distribution
    echo ""
    show_distribution "$plan_file"
}

# Main
plan_file=$(get_plan_file)

if [[ -z "$plan_file" ]] || [[ ! -f "$plan_file" ]]; then
    echo "ERROR: No plan file found" >&2
    exit 1
fi

case "${1:-auto}" in
    --check|-c)
        show_distribution "$plan_file"
        ;;
    --cleanup)
        cleanup_markers "$plan_file"
        show_distribution "$plan_file"
        ;;
    dev1)
        # Give tasks from dev2 to dev1
        rebalance_tasks "dev2" "dev1" "$plan_file"
        ;;
    dev2)
        # Give tasks from dev1 to dev2
        rebalance_tasks "dev1" "dev2" "$plan_file"
        ;;
    auto|"")
        # Auto-detect: give tasks to whoever has fewer
        dev1_tasks=$(count_unchecked "dev1" "$plan_file")
        dev2_tasks=$(count_unchecked "dev2" "$plan_file")

        echo "Current state:"
        echo "  dev1: $dev1_tasks tasks"
        echo "  dev2: $dev2_tasks tasks"
        echo ""

        if [[ "$dev1_tasks" -eq 0 ]] && [[ "$dev2_tasks" -gt 0 ]]; then
            echo "dev1 is idle, redistributing from dev2..."
            rebalance_tasks "dev2" "dev1" "$plan_file"
        elif [[ "$dev2_tasks" -eq 0 ]] && [[ "$dev1_tasks" -gt 0 ]]; then
            echo "dev2 is idle, redistributing from dev1..."
            rebalance_tasks "dev1" "dev2" "$plan_file"
        elif [[ "$dev1_tasks" -gt $((dev2_tasks + 3)) ]]; then
            echo "dev1 has significantly more, redistributing to dev2..."
            rebalance_tasks "dev1" "dev2" "$plan_file"
        elif [[ "$dev2_tasks" -gt $((dev1_tasks + 3)) ]]; then
            echo "dev2 has significantly more, redistributing to dev1..."
            rebalance_tasks "dev2" "dev1" "$plan_file"
        else
            echo "Tasks are reasonably balanced, no redistribution needed."
        fi
        ;;
    *)
        echo "Usage: ralph-rebalance.sh [dev1|dev2|--check|--cleanup|auto]"
        exit 1
        ;;
esac
