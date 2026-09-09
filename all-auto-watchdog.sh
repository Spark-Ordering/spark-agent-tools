#!/bin/bash
# Hourly (launchd com.carlos.all-auto-watchdog): if no Claude session holds an active /all-auto
# goal, or the newest such session has been silent for over an hour, tag Carlos in #engineering.
# Env: DRY_RUN=1, PROJECTS_GLOB, NOW_EPOCH, SLACK_BOT, STALE_SECONDS. ENG-2648.
set -euo pipefail

PROJECTS_GLOB="${PROJECTS_GLOB:-$HOME/.claude/projects/*/*.jsonl}"
SLACK_BOT="${SLACK_BOT:-$HOME/.claude/skills/claudeqs/slack-bot.sh}"
ENGINEERING_CHANNEL="${ENGINEERING_CHANNEL:-C0516TVR79B}"
CARLOS_ID="${CARLOS_ID:-U0516TWQHGD}"
STALE_SECONDS="${STALE_SECONDS:-3600}"
LOG="${ALL_AUTO_WATCHDOG_LOG:-$HOME/Library/Logs/all-auto-watchdog.log}"
DRY_RUN="${DRY_RUN:-0}"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

now_epoch() {
  if [ -n "${NOW_EPOCH:-}" ]; then echo "$NOW_EPOCH"; else date +%s; fi
}

# The goal a transcript currently holds: the args of its LAST /goal command ("" when none / cleared).
# Only real user command messages count — tool calls and results that quote the marker are ignored.
current_goal() {
  local file="$1"
  grep -a 'command-name>/goal</command-name>' "$file" \
    | jq -r 'select(.type == "user")
        | .message.content
        | if type == "string" then . else (map(select(.type == "text") | .text) | join("")) end
        | select(test("^\\s*<command-name>/goal</command-name>"))
        | capture("<command-args>(?<a>.*)</command-args>"; "s").a' 2>/dev/null \
    | tail -1 \
    | sed -E 's/^"//; s/"$//'
}

# Prints "<mtime-epoch>\t<file>" for every transcript whose current goal names /all-auto.
active_all_auto_sessions() {
  local file goal
  for file in $PROJECTS_GLOB; do
    [ -f "$file" ] || continue
    grep -aq 'command-name>/goal</command-name>' "$file" || continue
    goal="$(current_goal "$file")"
    case "$goal" in
      clear|"") continue ;;
    esac
    case "$goal" in
      *all-auto*) printf '%s\t%s\n' "$(stat -f '%m' "$file")" "$file" ;;
    esac
  done
}

alert() {
  local text="$1"
  log "ALERT: $text"
  if [ "$DRY_RUN" = "1" ]; then return; fi
  "$SLACK_BOT" post "$ENGINEERING_CHANNEL" "<@$CARLOS_ID> 🚨 /all-auto loop check: $text" >/dev/null
}

main() {
  local newest
  newest="$(active_all_auto_sessions | sort -rn | head -1)"
  if [ -z "$newest" ]; then
    alert "no Claude session holds an active /all-auto goal — the loop is not running. Fix it now."
    return
  fi
  local mtime file age
  mtime="${newest%%	*}"
  file="${newest#*	}"
  age=$(( $(now_epoch) - mtime ))
  if [ "$age" -gt "$STALE_SECONDS" ]; then
    alert "the /all-auto session $(basename "$file" .jsonl) last wrote $((age / 60)) min ago — the loop has stalled. Fix it now."
    return
  fi
  log "ok: $(basename "$file" .jsonl) active, last write $((age / 60)) min ago"
}

main
