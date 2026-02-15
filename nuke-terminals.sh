#!/bin/bash
# Kill all Terminal.app and iTerm2 windows
# Run before starting fresh emulator sessions to avoid clutter
#
# Usage: ./nuke-terminals.sh

osascript -e 'tell application "Terminal" to quit' 2>/dev/null
osascript -e 'tell application "iTerm" to quit' 2>/dev/null
sleep 1
echo "✓ All terminal windows closed"
