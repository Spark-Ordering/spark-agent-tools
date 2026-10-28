#!/bin/bash
# docker-idle-kill.sh — quit Docker Desktop when /all-auto has no ticket in flight.
# Called at the end of every idle /all-auto tick. Idempotent: no Docker → "docker: not running".
# The loop never needs Docker (deploy.sh uses `supabase functions deploy --use-api`).
set -euo pipefail

if ! pgrep -xq "com.docker.backend"; then
  echo "docker: not running"
  exit 0
fi

containers="$( (docker ps -q 2>/dev/null || true) | wc -l | tr -d ' ')"
# ponytail: quits regardless of running containers; add an allowlist if something else must survive idle ticks.
osascript -e 'quit app "Docker"' || true
sleep 15
# The graceful quit stops the VM + engine but leaves backend/UI processes behind (seen 2026-09-20).
pkill -x "com.docker.backend" || true
pkill -f "/Applications/Docker.app/Contents/MacOS/" || true
sleep 2
if pgrep -xq "com.docker.backend"; then
  echo "docker: backend survived pkill"
  exit 1
fi
echo "docker: quit (was running ${containers} containers)"
