#!/bin/bash
# claude-sync.sh - Bidirectional sync of Claude collaboration files between machines

# Add Homebrew to PATH for launchd
export PATH="/opt/homebrew/bin:$PATH"
#
# Usage:
#   claude-sync.sh              # Run sync once
#   claude-sync.sh --install    # Install launchd service (runs every 30s)
#   claude-sync.sh --uninstall  # Remove launchd service
#   claude-sync.sh --status     # Check if service is running
#
# Syncs: tasks, teams, plans, coordination folders

set -o pipefail

REMOTE="carlos@192.168.1.104"
REMOTE_HOST="192.168.1.104"
SYNC_DIRS=(
    "$HOME/.claude/tasks"
    "$HOME/.claude/teams"
    "$HOME/.claude/plans"
    "$HOME/.claude/coordination"
    "$HOME/.claude/hooks"
    "$HOME/.claude/skills"
    "$HOME/.claude/merge-staging"
)

# One-way sync dirs (dev1 → dev2 only, for code/scripts)
ONEWAY_DIRS=(
    "$HOME/Code/spark-agent-tools"
)
LOG_FILE="$HOME/.claude/logs/claude-sync.log"
LOCK_FILE="/tmp/claude-sync.lock"
PLIST_NAME="com.claude.sync"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if remote is reachable (quick timeout)
check_remote() {
    ssh -o ConnectTimeout=3 -o BatchMode=yes "$REMOTE" "echo ok" &>/dev/null
}

# Sync a directory bidirectionally
# Uses --update to only copy newer files (last-write-wins)
sync_dir() {
    local dir="$1"
    local dirname=$(basename "$dir")
    local parent=$(dirname "$dir")

    # Ensure local dir exists
    mkdir -p "$dir"

    # Push local → remote (only newer files)
    rsync -az --update --timeout=10 \
        "$dir/" "$REMOTE:$dir/" 2>/dev/null

    # Pull remote → local (only newer files)
    rsync -az --update --timeout=10 \
        "$REMOTE:$dir/" "$dir/" 2>/dev/null
}

# Sync a directory one-way (local → remote only)
# For code/scripts that should only be edited on dev1
sync_dir_oneway() {
    local dir="$1"

    # Push local → remote (delete on remote if deleted locally)
    rsync -az --delete --timeout=10 \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        "$dir/" "$REMOTE:$dir/" 2>/dev/null
}

do_sync() {
    # Use lock to prevent concurrent runs
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        exit 0  # Another sync is running, skip
    fi

    # Check if remote is reachable
    if ! check_remote; then
        log "Remote unreachable, skipping sync"
        exit 0
    fi

    # Sync each bidirectional directory
    for dir in "${SYNC_DIRS[@]}"; do
        if [[ -d "$dir" ]] || ssh -o ConnectTimeout=3 "$REMOTE" "[[ -d $dir ]]" 2>/dev/null; then
            sync_dir "$dir"
        fi
    done

    # Sync each one-way directory (dev1 → dev2)
    for dir in "${ONEWAY_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            sync_dir_oneway "$dir"
        fi
    done

    log "Sync complete"
}

install_service() {
    # Create launchd plist
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(realpath "$0")</string>
    </array>
    <key>StartInterval</key>
    <integer>10</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_FILE}</string>
    <key>StandardErrorPath</key>
    <string>${LOG_FILE}</string>
</dict>
</plist>
EOF

    # Load the service
    launchctl unload "$PLIST_PATH" 2>/dev/null
    launchctl load "$PLIST_PATH"

    echo "✅ Installed and started claude-sync service"
    echo "   Syncs every 10 seconds"
    echo "   Log: $LOG_FILE"
}

uninstall_service() {
    if [[ -f "$PLIST_PATH" ]]; then
        launchctl unload "$PLIST_PATH" 2>/dev/null
        rm -f "$PLIST_PATH"
        echo "✅ Uninstalled claude-sync service"
    else
        echo "Service not installed"
    fi
}

check_status() {
    if launchctl list | grep -q "$PLIST_NAME"; then
        echo "✅ claude-sync service is running"
        echo "   Last sync: $(tail -1 "$LOG_FILE" 2>/dev/null || echo 'No logs yet')"
    else
        echo "⏹️  claude-sync service is not running"
    fi
}

case "${1:-sync}" in
    --install|-i)
        install_service
        ;;
    --uninstall|-u)
        uninstall_service
        ;;
    --status|-s)
        check_status
        ;;
    sync|"")
        do_sync
        ;;
    *)
        echo "Usage: claude-sync.sh [--install|--uninstall|--status]"
        exit 1
        ;;
esac
