#!/bin/bash
# ralph-conversations.sh - Show the most recent conversations for dev1 and dev2
#
# Usage:
#   ralph-conversations.sh           # Show latest conversation IDs
#   ralph-conversations.sh dev1      # Show last N lines from dev1
#   ralph-conversations.sh dev2      # Show last N lines from dev2
#   ralph-conversations.sh dev2 tail # Just tail the file

DEV1_PROJECTS="$HOME/.claude/projects"
DEV2_HOST="carlos@192.168.1.104"
DEV2_PROJECTS="/Users/carlos/.claude/projects"

get_latest_local() {
    # Find the most recently modified .jsonl across ALL project dirs
    find "$DEV1_PROJECTS" -name "*.jsonl" -type f 2>/dev/null | \
        xargs ls -t 2>/dev/null | head -1
}

get_latest_remote() {
    ssh -o ConnectTimeout=3 "$DEV2_HOST" \
        "find $DEV2_PROJECTS -name '*.jsonl' -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1"
}

show_info() {
    echo "=== DEV1 (this machine) ==="
    local dev1_file=$(get_latest_local)
    if [[ -n "$dev1_file" ]]; then
        local dev1_id=$(basename "$dev1_file" .jsonl)
        local dev1_project=$(dirname "$dev1_file" | xargs basename)
        local dev1_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$dev1_file")
        echo "Session: $dev1_id"
        echo "Project: $dev1_project"
        echo "Modified: $dev1_time"
        echo "File: $dev1_file"
    else
        echo "No conversations found"
    fi

    echo ""
    echo "=== DEV2 (remote) ==="
    local dev2_file=$(get_latest_remote)
    if [[ -n "$dev2_file" ]]; then
        local dev2_id=$(basename "$dev2_file" .jsonl)
        local dev2_project=$(dirname "$dev2_file" | xargs basename)
        echo "Session: $dev2_id"
        echo "Project: $dev2_project"
        ssh "$DEV2_HOST" "stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' '$dev2_file'"
        echo "File: $dev2_file"
    else
        echo "No conversations found (or SSH failed)"
    fi
}

show_tail() {
    local agent="$1"
    local bytes="${2:-10000}"

    if [[ "$agent" == "dev1" ]]; then
        local file=$(get_latest_local)
        echo "=== Last messages from dev1: $(basename "$file") ==="
        tail -c "$bytes" "$file" | grep -oE '"content":"[^"]{0,200}"' | tail -20
    elif [[ "$agent" == "dev2" ]]; then
        local file=$(get_latest_remote)
        echo "=== Last messages from dev2: $(basename "$file") ==="
        ssh "$DEV2_HOST" "tail -c $bytes '$file'" | grep -oE '"content":"[^"]{0,200}"' | tail -20
    fi
}

case "${1:-info}" in
    info|"")
        show_info
        ;;
    dev1)
        if [[ "$2" == "tail" ]]; then
            get_latest_local
        else
            show_tail dev1 "${2:-10000}"
        fi
        ;;
    dev2)
        if [[ "$2" == "tail" ]]; then
            get_latest_remote
        else
            show_tail dev2 "${2:-10000}"
        fi
        ;;
    *)
        echo "Usage: $0 [info|dev1|dev2] [bytes|tail]"
        ;;
esac
