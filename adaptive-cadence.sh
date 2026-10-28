#!/bin/bash
# adaptive-cadence.sh — track an empty-tick streak for a named loop and print
# the recommended cron cadence. Also updates CLAUDE_CODE_GOAL_CHECKIN_MINUTES
# in ~/.claude/settings.json to match, so idle sessions check in less often.
#
# Usage:
#   adaptive-cadence.sh tick <loop-name> <count>
#     Feed one tick's activity count. 0 = idle; anything > 0 = productive.
#     Prints the recommended cron expression to stdout, e.g.
#       */3 * * * *    (fast, active)
#       */15 * * * *   (slow, after EMPTY_THRESHOLD consecutive zero ticks)
#
#   adaptive-cadence.sh state <loop-name>
#     Print the current stored state JSON. No state changes.
#
# Env overrides (all optional):
#   FAST_CRON        default "*/3 * * * *"
#   SLOW_CRON        default "*/15 * * * *"
#   FAST_MINUTES     default 3     — value written to CLAUDE_CODE_GOAL_CHECKIN_MINUTES
#   SLOW_MINUTES     default 15    — value written to CLAUDE_CODE_GOAL_CHECKIN_MINUTES
#   EMPTY_THRESHOLD  default 3     — consecutive zero-count ticks before slowing
#   SKIP_SETTINGS=1  do not touch ~/.claude/settings.json
#
# State: ~/.claude/adaptive-cadence/<loop-name>.json
set -euo pipefail

cmd="${1:-}"
name="${2:-}"

if [ -z "$cmd" ] || [ -z "$name" ]; then
  echo "usage: adaptive-cadence.sh tick|state <loop-name> [count]" >&2
  exit 2
fi
if ! [[ "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "loop-name must match [a-zA-Z0-9._-]" >&2
  exit 3
fi

state_dir="${HOME}/.claude/adaptive-cadence"
mkdir -p "$state_dir"
state_file="$state_dir/${name}.json"

if [ "$cmd" = "state" ]; then
  if [ -f "$state_file" ]; then cat "$state_file"; else echo '{}'; fi
  exit 0
fi

if [ "$cmd" != "tick" ]; then
  echo "unknown command: $cmd (expected tick or state)" >&2
  exit 2
fi

count="${3:-}"
if [ -z "$count" ] || ! [[ "$count" =~ ^-?[0-9]+$ ]]; then
  echo "tick needs an integer count as the third argument" >&2
  exit 4
fi

FAST_CRON="${FAST_CRON:-*/3 * * * *}"
SLOW_CRON="${SLOW_CRON:-*/15 * * * *}"
FAST_MINUTES="${FAST_MINUTES:-3}"
SLOW_MINUTES="${SLOW_MINUTES:-15}"
EMPTY_THRESHOLD="${EMPTY_THRESHOLD:-3}"

# Read prior streak
if [ -f "$state_file" ]; then
  streak=$(jq -r '.empty_streak // 0' "$state_file" 2>/dev/null || echo 0)
else
  streak=0
fi

# Update the streak: zero ticks accumulate, any positive count resets.
if [ "$count" -eq 0 ]; then
  streak=$((streak + 1))
else
  streak=0
fi

if [ "$streak" -ge "$EMPTY_THRESHOLD" ]; then
  new_cadence=slow
else
  new_cadence=fast
fi

# Persist state.
jq -n \
  --arg name "$name" \
  --argjson streak "$streak" \
  --arg cadence "$new_cadence" \
  --arg updated "$(date -u +%FT%TZ)" \
  --argjson count "$count" \
  '{loop: $name, empty_streak: $streak, cadence: $cadence, last_count: $count, updated_at: $updated}' \
  > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"

# Sync the goal-checkin minutes in ~/.claude/settings.json unless opted out.
if [ -z "${SKIP_SETTINGS:-}" ]; then
  settings="${HOME}/.claude/settings.json"
  if [ -f "$settings" ]; then
    if [ "$new_cadence" = "slow" ]; then
      desired="$SLOW_MINUTES"
    else
      desired="$FAST_MINUTES"
    fi
    current=$(jq -r '.env.CLAUDE_CODE_GOAL_CHECKIN_MINUTES // ""' "$settings" 2>/dev/null || echo "")
    if [ "$current" != "$desired" ]; then
      jq --arg v "$desired" '.env.CLAUDE_CODE_GOAL_CHECKIN_MINUTES = $v' "$settings" \
        > "${settings}.tmp" && mv "${settings}.tmp" "$settings"
    fi
  fi
fi

# Print the recommended cron so the caller can pass it to CronCreate.
if [ "$new_cadence" = "slow" ]; then
  echo "$SLOW_CRON"
else
  echo "$FAST_CRON"
fi
