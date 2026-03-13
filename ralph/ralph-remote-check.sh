#!/bin/bash
# ralph-remote-check.sh - Check if the other Ralph machine is reachable
#
# Usage:
#   source ralph-remote-check.sh
#   if is_remote_online; then echo "online"; fi
#
# Or standalone:
#   ralph-remote-check.sh   # exits 0 if online, 1 if offline

RALPH_REMOTE_HOST="${RALPH_REMOTE_HOST:-192.168.1.104}"
RALPH_REMOTE_USER="${RALPH_REMOTE_USER:-carlos}"

is_remote_online() {
    ssh -o ConnectTimeout=3 -o BatchMode=yes \
        "${RALPH_REMOTE_USER}@${RALPH_REMOTE_HOST}" "echo ok" 2>/dev/null \
        | grep -q "ok"
}

# If run directly (not sourced), exit with the result
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if is_remote_online; then
        echo "online"
        exit 0
    else
        echo "offline"
        exit 1
    fi
fi
