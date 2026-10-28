#!/usr/bin/env bash
# Toggle the all-auto watchdog launchd job (com.carlos.all-auto-watchdog) on/off.
# Persists across reboots via launchctl disable/enable; stops/starts it immediately.
# Idempotent: running it twice returns to the original state.
set -euo pipefail

LABEL="com.carlos.all-auto-watchdog"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
GUI="gui/$(id -u)"

if [ ! -f "$PLIST" ]; then
  echo "ERROR: $PLIST not found" >&2
  exit 1
fi

disabled_now() {
  launchctl print-disabled "$GUI" 2>/dev/null | grep -F "\"$LABEL\" => disabled" >/dev/null
}

if disabled_now; then
  launchctl enable "$GUI/$LABEL"
  launchctl bootstrap "$GUI" "$PLIST" 2>/dev/null || true
  echo "all-auto watchdog: ON (alerts resume, hourly check in #engineering)"
else
  launchctl disable "$GUI/$LABEL"
  launchctl bootout "$GUI/$LABEL" 2>/dev/null || true
  echo "all-auto watchdog: OFF (no more all-auto stall alerts until you toggle back on)"
fi
